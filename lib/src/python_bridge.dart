import 'dart:async';
import 'dart:io' if (dart.library.html) 'package:flutter_python_bridge/src/web_stub.dart';

import 'package:flutter_python_bridge/src/models/python_result.dart';
import 'package:flutter_python_bridge/src/python_executor.dart';
import 'package:flutter_python_bridge/src/python_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// The main class for interacting with Python code in Flutter.
class PythonBridge {
  /// The Python executor instance
  final PythonExecutor _executor;
  
  /// The Python service for platform-specific implementations
  final PythonService _service;
  
  /// Whether to use Chaquopy on Android (if available)
  final bool useChaquopyOnAndroid;

  /// Creates a new [PythonBridge] instance.
  PythonBridge({
    String? pythonExecutablePath,
    List<String> additionalPythonPaths = const [],
    this.useChaquopyOnAndroid = true,
  }) : _executor = PythonExecutor(
          pythonExecutablePath: pythonExecutablePath,
          additionalPythonPaths: additionalPythonPaths,
        ),
       _service = PythonService();

  /// Runs Python code and returns the result.
  /// 
  /// [code] is the Python code to run.
  /// 
  /// Returns a [PythonResult] containing the output and any error.
  Future<PythonResult> runCode(String code) async {
    // Check if running on web
    if (isWeb()) {
      return PythonResult.failure(
        error: 'Running Python code directly is not supported on web platforms. '
             'Consider using a backend service or API instead.',
        output: 'Web platform detected - Python execution not available',
      );
    }
    
    // Check if running on iOS
    if (Platform.isIOS) {
      return PythonResult.failure(
        error: 'Running Python code directly is not supported on iOS due to platform restrictions. '
             'Consider using a backend service or API instead.',
        output: 'iOS platform detected - Python execution not available',
      );
    }
    
    if (Platform.isAndroid && useChaquopyOnAndroid) {
      try {
        final Map<dynamic, dynamic> result = await _service.invokeMethod(
          'runPythonCode',
          {'code': code},
        );

        final bool success = result['success'] ?? false;
        final String? output = result['output'];
        final String? error = result['error'];
        final dynamic returnValue = result['returnValue'];

        if (success) {
          return PythonResult.success(
            output: output,
            returnValue: returnValue,
          );
        } else {
          return PythonResult.failure(
            error: error,
            output: output,
          );
        }
      } catch (e) {
        return PythonResult.failure(error: e.toString());
      }
    } else {
      return _executor.executeCode(code);
    }
  }

  /// Runs a Python script file and returns the result.
  /// 
  /// Example:
  /// ```dart
  /// final result = await pythonBridge.runScript('path/to/script.py');
  /// 
  /// if (result.success) {
  ///   print('Output: ${result.output}');
  /// } else {
  ///   print('Error: ${result.error}');
  /// }
  /// ```
  Future<PythonResult> runScript(String scriptPath) async {
    // Check if we should use the platform-specific implementation
    if (Platform.isAndroid && useChaquopyOnAndroid) {
      return _service.runPythonScript(scriptPath);
    }
    
    // Use the generic executor
    return _executor.executeFile(scriptPath);
  }

  /// Installs a Python package using pip.
  /// 
  /// This allows developers to install Python packages at runtime without
  /// having to restart the app. This is particularly useful for advanced
  /// use cases where specific packages are needed but might not be available
  /// by default.
  /// 
  /// Example:
  /// ```dart
  /// final result = await pythonBridge.installPackage('seaborn');
  /// 
  /// if (result.success) {
  ///   print('Package installed successfully');
  /// } else {
  ///   print('Error installing package: ${result.error}');
  /// }
  /// ```
  /// 
  /// Note: This method requires an internet connection and may take some time
  /// depending on the package size and dependencies.
  Future<PythonResult> installPackage(String packageName) async {
    if (Platform.isAndroid && useChaquopyOnAndroid) {
      try {
        // Use the method channel to install the package on Android
        final Map<dynamic, dynamic> result = await _service.invokeMethod(
          'installPythonPackage',
          {'packageName': packageName},
        );
        
        // Convert the result to the expected format
        return PythonResult(
          success: result['success'] == true,
          output: result['output']?.toString() ?? '',
          error: result['error']?.toString() ?? '',
          returnValue: result['installed'] != null 
              ? 'Package ${result['installed'] == true ? 'successfully installed' : 'installation completed but import failed'}'
              : null,
        );
      } catch (e) {
        // If the method channel fails, fall back to the executor
        try {
          return await _executor.installPackage(packageName);
        } catch (fallbackError) {
          return PythonResult(
            success: false,
            error: 'Failed to install package: $e, fallback error: $fallbackError',
          );
        }
      }
    } else {
      // For non-Android platforms, use the executor directly
      try {
        return await _executor.installPackage(packageName);
      } catch (e) {
        return PythonResult(
          success: false,
          error: e.toString(),
        );
      }
    }
  }

  /// Creates a Python script file with the given content and returns the file path.
  /// 
  /// This is useful for creating Python scripts that can be executed later.
  Future<String> createPythonScript(String pythonCode, {String? fileName}) async {
    final tempDir = await getTemporaryDirectory();
    final scriptName = fileName ?? 'script_${DateTime.now().millisecondsSinceEpoch}.py';
    final filePath = path.join(tempDir.path, scriptName);
    
    final file = File(filePath);
    await file.writeAsString(pythonCode);
    
    return filePath;
  }

  /// Checks if Python is installed and available.
  Future<bool> isPythonAvailable() async {
    if (Platform.isAndroid && useChaquopyOnAndroid) {
      return _service.isPythonAvailable();
    }
    
    try {
      final pythonExecutable = _executor.pythonExecutablePath ?? 
          (Platform.isWindows ? 'python' : 'python3');
      
      final result = await Process.run(
        pythonExecutable,
        ['--version'],
      );
      
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Gets the Python version.
  Future<String?> getPythonVersion() async {
    if (Platform.isAndroid && useChaquopyOnAndroid) {
      return _service.getPythonVersion();
    }
    
    try {
      final pythonExecutable = _executor.pythonExecutablePath ?? 
          (Platform.isWindows ? 'python' : 'python3');
      
      final result = await Process.run(
        pythonExecutable,
        ['--version'],
      );
      
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim().isNotEmpty
            ? result.stdout.toString().trim()
            : result.stderr.toString().trim();
        return output;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Helper method to detect if running on web platform
  bool isWeb() {
    try {
      return identical(0, 0.0);
    } catch (_) {
      return false;
    }
  }
}
