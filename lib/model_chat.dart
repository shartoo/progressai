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
  /// [prompt] 系统提示词
  /// [imageBytes] 可选的图片数据
  /// [onToken] 每个token的回调函数
  /// 
  /// 返回是否成功
  Future<bool> chatStream({
    required InferenceChat chatEngine,
    required String text,
    Uint8List? imageBytes,
    required Function(String token) onToken,
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
      // 添加用户消息到聊天
      String responseText = "";
      await chatEngine.addQueryChunk(userMessage);
      chatEngine.generateChatResponseAsync().listen((ModelResponse response) {
        if (response is TextResponse) {
          responseText = response.token;
        }
      }, onDone: () {
        print('Chat stream closed');
      }, onError: (error) {
        print('Chat error: $error');
      });

      // 将结果按字符分割并逐个回调
      for (int i = 0; i < responseText.length; i++) {
        onToken(responseText[i]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static String cleanJsonResponse(String jsonString) {
    try {
      // 尝试解析外部 JSON，获取 'message' 字段的内容
      final Map<String, dynamic> outerJson = jsonDecode(jsonString);
      if (outerJson.containsKey('message') && outerJson['message'] is String) {
        String innerContent = outerJson['message'];

        // 移除 Markdown 代码块标记
        // 匹配 "```json\n" 或 "```"
        innerContent = innerContent.replaceAll(RegExp(r'```json\n'), '');
        innerContent = innerContent.replaceAll(RegExp(r'\n```'), '');

        return innerContent.trim(); // 移除首尾空白
      }
    } catch (e) {
      // 如果解析外部 JSON 失败，或者没有 'message' 字段，
      // 那么假设整个字符串就是被 Markdown 包裹的 JSON
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

/// 预定义的提示词模板
class PromptTemplates {
  /// 减肥助手提示词
  static const String weightManagement = '''
    您是一个专业的AI减肥助手。您的目标是帮助用户健康减肥，提供个性化建议和鼓励。
    
    您的职责包括：
    1. 分析用户的饮食和运动情况
    2. 提供个性化的减肥建议
    3. 鼓励用户坚持健康的生活方式
    4. 回答关于营养、运动、心理健康的问题
    5. 帮助用户设定和跟踪减肥目标
    
    请用友好、专业、鼓励的语气回复用户。
''';

  /// 阅读助手提示词
  static const String readingAssistant = '''
    您是一个专业的AI阅读助手。您的目标是帮助用户更好地理解和分析文本内容。
    
    您的功能包括：
    1. 总结文章的主要内容和关键观点
    2. 分析文本的结构和逻辑
    3. 回答用户关于文本内容的问题
    4. 提供个性化的阅读建议
    5. 帮助用户深入理解复杂概念
    
    请用清晰、准确、有帮助的方式回复用户。
''';

  /// 通用助手提示词
  static const String generalAssistant = '''
您是一个有用的AI助手。请根据用户的需求提供准确、有帮助的回复。
请确保回复：
1. 准确且相关
2. 清晰易懂
3. 有帮助且实用
4. 友好且专业
''';
} 