import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class ModelChat {
  final _gemma = FlutterGemmaPlugin.instance;
  InferenceModel? _inferenceModel;
  String modelFilename = "gemma-3n-E4B-it-int4.task";
  String modelUrl = 'https://hf-mirror.com//google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task';
  String gemmaToken = "";
  /// init gemma model
  Future<InferenceChat?> initializeGemmaChat({Function(double)? onProgress}) async {
    try {
      final modelDocPath = await getGemmaModelPath();
      final modelFile = File(modelDocPath);
      if (!modelFile.existsSync()) {
        print("model file $modelDocPath not exist！，downloading it from hugging face $modelUrl");
        await downloadModel(
          token:gemmaToken,
          onProgress: (progress) {
            if (onProgress != null) {
              onProgress(progress);
            }
          },
        );
      }
      _gemma.modelManager.setModelPath(modelDocPath);
      _inferenceModel = await _gemma.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: PreferredBackend.gpu,
        maxTokens: 4096,
        supportImage: true, // Pass image support
        maxNumImages: 1, // Maximum 4 images for multimodal models
      );
      print("model createModel success!");
      InferenceChat? chatEngine = await _inferenceModel?.createChat(
        temperature: 0.8,
        randomSeed: 1,
        topK: 1,
        topP: 0.8,
        tokenBuffer: 256,
        supportImage: true,
        supportsFunctionCalls: false,
        tools: [],
        isThinking: false,
        modelType: ModelType.gemmaIt,
      );
      print("create model chat success!");
      return chatEngine;
    } catch (e) {
      throw Exception('Failed to initialize model: $e');
    }
  }

  Future<String> getGemmaModelPath() async {
    // /data/data/com.xxx.xxx/app_flutter/
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$modelFilename';
  }
  /// Downloads the model file and tracks progress.
  Future<void> downloadModel({
    required String token,
    required Function(double) onProgress,
  }) async {
    http.StreamedResponse? response;
    IOSink? fileSink;

    try {
      final filePath = await getGemmaModelPath();
      final file = File(filePath);
      // Check if file already exists and partially downloaded
      int downloadedBytes = 0;
      if (file.existsSync()) {
        downloadedBytes = await file.length();
      }
      // Create HTTP request
      final request = http.Request('GET', Uri.parse(modelUrl));
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Resume download if partially downloaded
      if (downloadedBytes > 0) {
        request.headers['Range'] = 'bytes=$downloadedBytes-';
      }

      // Send request and handle response
      response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentLength = response.contentLength ?? 0;
        final totalBytes = downloadedBytes + contentLength;
        fileSink = file.openWrite(mode: FileMode.append);
        int received = downloadedBytes;
        // Listen to the stream and write to the file
        await for (final chunk in response.stream) {
          fileSink.add(chunk);
          received += chunk.length;

          // Update progress
          onProgress(totalBytes > 0 ? received / totalBytes : 0.0);
        }
      } else {
        if (kDebugMode) {
          print('Failed to download model. Status code: ${response.statusCode}');
          print('Headers: ${response.headers}');
          try {
            final errorBody = await response.stream.bytesToString();
            print('Error body: $errorBody');
          } catch (e) {
            print('Could not read error body: $e');
          }
        }
        throw Exception('Failed to download the model.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading model: $e');
      }
      rethrow;
    } finally {
      if (fileSink != null) await fileSink.close();
    }
  }
  /// 与AI模型进行对话
  /// 
  /// [text] 用户输入的文本
  /// [prompt] 系统提示词，用于设置AI的角色和行为
  /// [imageBytes] 可选的图片数据
  /// 
  /// 返回JSON格式的响应：
  /// {
  ///   "success": true/false,
  ///   "message": "AI回复内容",
  ///   "error": "错误信息（如果有）"
  /// }
  Future<String> chat({
    required InferenceChat chatEngine,
    required String text,
    Uint8List? imageBytes,
  }) async {
    try {
      // 创建用户消息
      final userMessage = imageBytes != null 
        ? Message.withImage(
            text: text,
            imageBytes: imageBytes,
            isUser: true,
          )
        : Message(
            text: text,
            isUser: true,
          );
      // 生成回复
      String responseText = '';
      // 添加用户消息到聊天
      await chatEngine.addQueryChunk(userMessage);
      ModelResponse response = await chatEngine.generateChatResponse();
      if (response is TextResponse) {
        responseText = response.token;
      } else{
        responseText = "";
      }
      // 返回成功响应
      return jsonEncode({
        "success": true,
        "message": responseText.trim(),
        "error": null,
      });

    } catch (e) {
      // 返回错误响应
      return jsonEncode({
        "success": false,
        "message": null,
        "error": e.toString(),
      });
    }
  }

  /// 流式对话方法
  ///
  /// [text] 用户输入的文本
  /// [chatEngine] 聊天引擎实例
  /// [imageBytes] 可选的图片数据
  /// [onToken] 每个token的回调函数，用于实时更新UI
  ///
  /// 返回Future<void>，表示流处理的完成或错误。
  Future<void> chatStream({
    required InferenceChat chatEngine,
    required String text,
    Uint8List? imageBytes,
    required Function(String token) onToken, // This callback will be invoked for each token
  }) async {
    try {
      final userMessage = imageBytes != null
          ? Message.withImage(
        text: text,
        imageBytes: imageBytes,
        isUser: true,
      )
          : Message(
        text: text,
        isUser: true,
      );

      await chatEngine.addQueryChunk(userMessage);

      // Use a Completer to wait for the stream to complete or error
      final completer = Completer<void>();

      chatEngine.generateChatResponseAsync().listen(
            (ModelResponse response) {
          if (response is TextResponse) {
            onToken(response.token); // Call the provided callback with each token
          }
        },
        onDone: () {
          print('Chat stream closed');
          completer.complete(); // Mark the Future as complete when the stream is done
        },
        onError: (error) {
          print('Chat error: $error');
          completer.completeError(error); // Mark the Future with an error
        },
        cancelOnError: true, // Automatically cancel subscription on error
      );

      await completer.future; // Wait for the stream to complete or error
    } catch (e) {
      print('Error in ModelChat.chatStream: $e');
      rethrow; // Re-throw the error to the caller
    }
  }

  static String cleanJsonResponse(String jsonString) {
    try {
      // 尝试解析外部 JSON，获取 'message' 字段的内容
      final Map<String, dynamic> outerJson = jsonDecode(jsonString);
      if (outerJson.containsKey('message') && outerJson['message'] is String) {
        String innerContent = outerJson['message'];

        // remove Markdown tags
        // match "```json\n" 或 "```"
        innerContent = innerContent.replaceAll(RegExp(r'```json\n'), '');
        innerContent = innerContent.replaceAll(RegExp(r'\n```'), '');

        return innerContent.trim(); // 移除首尾空白
      }
    } catch (e) {
      print('Failed to parse outer JSON or missing "message" field, attempting direct Markdown strip: $e');
    }

    // 备用方案：直接移除 Markdown 代码块标记
    String cleaned = jsonString.replaceAll(RegExp(r'```json\n'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n```'), '');
    return cleaned.trim();
  }

  /// 解析聊天响应
  /// 
  /// [jsonResponse] JSON格式的响应字符串
  /// 返回解析后的Map对象
  static Map<String, dynamic> parseResponse(String jsonResponse) {
    try {
      return jsonDecode(jsonResponse);
    } catch (e) {
      return {
        "success": false,
        "message": null,
        "error": "响应解析失败: $e",
      };
    }
  }

  /// 检查响应是否成功
  /// 
  /// [response] 解析后的响应Map
  /// 返回是否成功
  static bool isSuccess(Map<String, dynamic> response) {
    return response["success"] == true;
  }

  /// 获取响应消息
  /// 
  /// [response] 解析后的响应Map
  /// 返回消息内容
  static String? getMessage(Map<String, dynamic> response) {
    return response["message"];
  }

  /// 获取错误信息
  /// 
  /// [response] 解析后的响应Map
  /// 返回错误信息
  static String? getError(Map<String, dynamic> response) {
    return response["error"];
  }
}



