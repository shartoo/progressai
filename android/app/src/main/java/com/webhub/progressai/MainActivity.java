package com.webhub.progressai;

import io.flutter.embedding.android.FlutterActivity;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import java.io.File;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.webhub.progressai/file_access";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("getModelFile")) {
                                String fileName = call.argument("fileName");
                                if (fileName != null) {
                                    File file = getModelFile(fileName);
                                    if (file != null) {
                                        result.success(file.getAbsolutePath());
                                    } else {
                                        result.error("FILE_NOT_FOUND", "File not found: " + fileName, null);
                                    }
                                } else {
                                    result.error("INVALID_ARGUMENT", "File name is null", null);
                                }
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private File getModelFile(String fileName) {
        // 这是 ADB 推送文件的默认路径
        // 注意：你需要根据实际的推送路径修改这里
        // 例如：adb push model.bin /data/local/tmp/
        File file = new File("/data/local/tmp/", fileName);

        if (file.exists()) {
            return file;
        } else {
            // 如果文件不在上述路径，你可能需要检查其他位置
            return null;
        }
    }
}