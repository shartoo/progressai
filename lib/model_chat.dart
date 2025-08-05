import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Added for UI elements (AlertDialog, TextField, etc.)
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for local storage

class ModelChat {
  final _gemma = FlutterGemmaPlugin.instance;
  InferenceModel? _inferenceModel;
  String modelFilename = "gemma-3n-E4B-it-int4.task";
  String modelUrl = 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/blob/main/gemma-3n-E4B-it-int4.task';
  String gemmaToken = "";

  Future<InferenceChat?> initializeGemmaChat(BuildContext context, {Function(double)? onProgress}) async {
    try {
      // 1. Load existing token from local storage
      gemmaToken = await _loadGemmaToken();
      print("Loaded Gemma Token: ${gemmaToken.isNotEmpty ? 'Exists' : 'Empty'}");
      final modelDocPath = await getGemmaModelPath();
      final modelFile = File(modelDocPath);
      // Check if model file exists AND was successfully downloaded previously
      final prefs = await SharedPreferences.getInstance();
      bool isModelDownloadedSuccessfully = prefs.getBool('model_downloaded_$modelFilename') ?? false;
      // 2. If model file does not exist OR it exists but was not successfully downloaded (e.g., corrupted, incomplete previous download), initiate download flow
      if (!modelFile.existsSync() || !isModelDownloadedSuccessfully) {
        print("Model file not found or not successfully downloaded. Initiating download/re-download.");
        // 2.1. If token is empty, prompt user for token
        if (gemmaToken.isEmpty) {
          final enteredToken = await _showTokenInputDialog(context);
          if (enteredToken == null || enteredToken.isEmpty) {
            // User cancelled or entered empty token, cannot proceed with download
            throw Exception('Gemma API Token is required to download the model.');
          }
          gemmaToken = enteredToken;
          await _saveGemmaToken(enteredToken); // Save the newly entered token
        }

        // 2.2. Show download progress dialog
        final progressController = StreamController<double>();
        // Using a separate context for dialog to ensure it's not dismissed by route changes
        showDialog(
          context: context,
          barrierDismissible: false, // Prevent dismissal by tapping outside
          builder: (dialogContext) => _DownloadProgressDialog(progressStream: progressController.stream),
        );

        try {
          // 2.3. Start model download
          await downloadModel(
            token: gemmaToken,
            onProgress: (progress) {
              progressController.add(progress); // Send progress updates to the dialog
              onProgress?.call(progress); // Also call original onProgress callback if provided
            },
          );
          // 2.4. Dismiss download dialog on success
          Navigator.of(context).pop();
          print("Model downloaded successfully!");

          // After download, re-check the flag and file existence to confirm success
          isModelDownloadedSuccessfully = prefs.getBool('model_downloaded_$modelFilename') ?? false;
          if (!isModelDownloadedSuccessfully || !modelFile.existsSync()) {
            throw Exception('Model download failed or file is corrupted. Cannot initialize model.');
          }

        } catch (e) {
          // 2.5. Dismiss dialog and re-throw error on download failure
          Navigator.of(context).pop();
          throw Exception('Failed to download model: $e');
        } finally {
          await progressController.close(); // Close the stream controller
        }
      }

      // 3. Set model path and create model/chat engine
      // Now, we are confident the model file should be present and valid
      _gemma.modelManager.setModelPath(modelDocPath);
      print('create model manage from file path $modelDocPath');
      _inferenceModel = await _gemma.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: PreferredBackend.gpu,
        maxTokens: 4096,
        supportImage: true,
        maxNumImages: 1,
      );
      print("Model createModel success!");

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
      print("Create model chat success!");
      return chatEngine;
    } catch (e) {
      print('Failed to initialize model: $e');
      throw Exception('Failed to initialize model: $e');
    }
  }

  /// Gets the local path for the Gemma model file.
  Future<String> getGemmaModelPath() async {
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
    final prefs = await SharedPreferences.getInstance();

    try {
      final filePath = await getGemmaModelPath();
      print('Downloading model into file $filePath');
      final file = File(filePath);

      int downloadedBytes = 0;
      if (file.existsSync()) {
        downloadedBytes = await file.length();
      }

      final request = http.Request('GET', Uri.parse(modelUrl));
      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (downloadedBytes > 0) {
        request.headers['Range'] = 'bytes=$downloadedBytes-';
      }

      response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentLength = response.contentLength ?? 0;
        final totalBytes = downloadedBytes + contentLength;
        fileSink = file.openWrite(mode: FileMode.append);

        int received = downloadedBytes;

        await for (final chunk in response.stream) {
          fileSink.add(chunk);
          received += chunk.length;
          onProgress(totalBytes > 0 ? received / totalBytes : 0.0);
        }

        // --- NEW: Verify final file size after download completes ---
        final finalFileSize = await file.length();
        if (finalFileSize != totalBytes) {
          // If sizes don't match, it means the download was incomplete or corrupted
          await prefs.setBool('model_downloaded_$modelFilename', false);
          throw Exception('Downloaded model file size mismatch. Expected $totalBytes bytes, got $finalFileSize bytes.');
        }
        // --- END NEW ---

        await prefs.setBool('model_downloaded_$modelFilename', true); // Update preference key
      } else {
        await prefs.setBool('model_downloaded_$modelFilename', false); // Update preference key
        if (kDebugMode) {
          print(
            'Failed to download model. Status code: ${response.statusCode}',
          );
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
      await prefs.setBool('model_downloaded_$modelFilename', false); // Update preference key
      if (kDebugMode) {
        print('Error downloading model: $e');
      }
      rethrow;
    } finally {
      if (fileSink != null) await fileSink.close();
    }
  }

  /// Displays a dialog to prompt the user for the Gemma API Token.
  Future<String?> _showTokenInputDialog(BuildContext context) async {
    final TextEditingController tokenController = TextEditingController(text: gemmaToken); // Pre-fill with existing token
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // User must enter or cancel
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Gemma API Token Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your Hugging Face API Token to download the Gemma model:'),
              const SizedBox(height: 10),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(
                  hintText: 'hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                  border: OutlineInputBorder(),
                ),
                obscureText: true, // Hide token input
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(null); // Return null on cancel
              },
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(dialogContext).pop(tokenController.text); // Return entered token
              },
            ),
          ],
        );
      },
    );
  }

  /// Saves the Gemma API Token to SharedPreferences.
  Future<void> _saveGemmaToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemma_api_token', token);
  }

  /// Loads the Gemma API Token from SharedPreferences.
  Future<String> _loadGemmaToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gemma_api_token') ?? '';
  }

  /// Interacts with the AI model (non-streaming).
  /// This method is kept for compatibility but `chatStream` is preferred for new uses.
  Future<String> chat({
    required InferenceChat chatEngine,
    required String text,
    Uint8List? imageBytes,
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
      String responseText = '';
      await chatEngine.addQueryChunk(userMessage);
      ModelResponse response = await chatEngine.generateChatResponse();
      if (response is TextResponse) {
        responseText = response.token;
      } else {
        responseText = "";
      }
      return jsonEncode({
        "success": true,
        "message": responseText.trim(),
        "error": null,
      });
    } catch (e) {
      return jsonEncode({
        "success": false,
        "message": null,
        "error": e.toString(),
      });
    }
  }

  /// Streams conversation with the AI model.
  Future<void> chatStream({
    required InferenceChat chatEngine,
    required String text,
    Uint8List? imageBytes,
    required Function(String token) onToken, // Callback for each streamed token
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

      final completer = Completer<void>();

      chatEngine.generateChatResponseAsync().listen(
            (ModelResponse response) {
          if (response is TextResponse) {
            onToken(response.token);
          }
        },
        onDone: () {
          print('Chat stream closed');
          completer.complete();
        },
        onError: (error) {
          print('Chat error: $error');
          completer.completeError(error);
        },
        cancelOnError: true,
      );

      await completer.future;
    } catch (e) {
      print('Error in ModelChat.chatStream: $e');
      rethrow;
    }
  }

  /// Cleans JSON response text by removing Markdown code block tags.
  static String cleanJsonResponse(String jsonString) {
    try {
      final Map<String, dynamic> outerJson = jsonDecode(jsonString);
      if (outerJson.containsKey('message') && outerJson['message'] is String) {
        String innerContent = outerJson['message'];
        innerContent = innerContent.replaceAll(RegExp(r'```json\n'), '');
        innerContent = innerContent.replaceAll(RegExp(r'\n```'), '');
        return innerContent.trim();
      }
    } catch (e) {
      print('Failed to parse outer JSON or missing "message" field, attempting direct Markdown strip: $e');
    }
    String cleaned = jsonString.replaceAll(RegExp(r'```json\n'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n```'), '');
    return cleaned.trim();
  }

  /// Parses a JSON chat response string into a Map.
  static Map<String, dynamic> parseResponse(String jsonResponse) {
    try {
      return jsonDecode(jsonResponse);
    } catch (e) {
      return {
        "success": false,
        "message": null,
        "error": "Response parsing failed: $e",
      };
    }
  }

  /// Checks if a parsed response indicates success.
  static bool isSuccess(Map<String, dynamic> response) {
    return response["success"] == true;
  }

  /// Gets the message content from a parsed response.
  static String? getMessage(Map<String, dynamic> response) {
    return response["message"];
  }

  /// Gets the error message from a parsed response.
  static String? getError(Map<String, dynamic> response) {
    return response["error"];
  }
}

/// A dialog widget to display model download progress.
class _DownloadProgressDialog extends StatefulWidget {
  final Stream<double> progressStream;

  const _DownloadProgressDialog({Key? key, required this.progressStream}) : super(key: key);

  @override
  __DownloadProgressDialogState createState() => __DownloadProgressDialogState();
}

class __DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;
  late StreamSubscription<double> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.progressStream.listen((progress) {
      if (mounted) { // Ensure widget is still in the tree
        setState(() {
          _progress = progress;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Downloading Model'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 10),
          Text('${(_progress * 100).toInt()}% downloaded'),
        ],
      ),
    );
  }
}
