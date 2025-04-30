import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_python_bridge/src/models/python_result.dart';
import 'package:flutter_python_bridge/src/python_executor.dart';

/// A service that provides platform-specific Python execution capabilities.
class PythonService {
  static const MethodChannel _channel = MethodChannel('flutter_python_bridge');
  final PythonExecutor _executor = PythonExecutor();

  /// Runs Python code using platform-specific implementations if available,
  /// otherwise falls back to the generic executor.
  Future<PythonResult> runPythonCode(String pythonCode) async {
    try {
      if (Platform.isAndroid) {
        try {
          // Try to use the method channel first
          final result = await _channel.invokeMethod('runPythonCode', {
            'code': pythonCode,
          });
          
          if (result != null && result is Map) {
            if (result['success'] == true) {
              return PythonResult.success(
                output: result['output'],
                returnValue: result['returnValue'],
              );
            } else {
              return PythonResult.failure(
                error: result['error'],
                output: result['output'],
              );
            }
          }
        } catch (e) {
          // If method channel fails, fall back to the executor
          return await _executor.executeCode(pythonCode);
        }
      }
      
      // Use the generic executor for other platforms
      return await _executor.executeCode(pythonCode);
    } catch (e) {
      return PythonResult.failure(error: e.toString());
    }
  }

  /// Runs a Python script file using platform-specific implementations if available,
  /// otherwise falls back to the generic executor.
  Future<PythonResult> runPythonScript(String scriptPath) async {
    try {
      if (Platform.isAndroid) {
        try {
          // Try to use the method channel first
          final result = await _channel.invokeMethod('runPythonScript', {
            'scriptPath': scriptPath,
          });
          
          if (result != null && result is Map) {
            if (result['success'] == true) {
              return PythonResult.success(
                output: result['output'],
                returnValue: result['returnValue'],
              );
            } else {
              return PythonResult.failure(
                error: result['error'],
                output: result['output'],
              );
            }
          }
        } catch (e) {
          // If method channel fails, fall back to the executor
          return await _executor.executeFile(scriptPath);
        }
      }
      
      // Use the generic executor for other platforms
      return await _executor.executeFile(scriptPath);
    } catch (e) {
      return PythonResult.failure(error: e.toString());
    }
  }

  /// Installs a Python package using platform-specific implementations if available,
  /// otherwise falls back to the generic approach.
  Future<PythonResult> installPythonPackage(String packageName) async {
    try {
      if (Platform.isAndroid) {
        try {
          // Try to use the method channel first
          final result = await _channel.invokeMethod('installPythonPackage', {
            'packageName': packageName,
          });
          
          if (result != null && result is Map) {
            if (result['success'] == true) {
              return PythonResult.success(
                output: result['output'],
              );
            } else {
              return PythonResult.failure(
                error: result['error'],
                output: result['output'],
              );
            }
          }
        } catch (e) {
          // If method channel fails, fall back to the generic approach
        }
      }
      
      // Use a generic approach for installing packages
      final pythonExecutable = Platform.isWindows ? 'python' : 'python3';
      
      try {
        final result = await Process.run(
          pythonExecutable,
          ['-m', 'pip', 'install', packageName],
        );
        
        if (result.exitCode == 0) {
          return PythonResult.success(
            output: 'Successfully installed $packageName\n${result.stdout}',
          );
        } else {
          return PythonResult.failure(
            error: 'Failed to install $packageName: ${result.stderr}',
            output: result.stdout.toString(),
          );
        }
      } catch (e) {
        return PythonResult.failure(
          error: 'Exception while installing $packageName: $e',
        );
      }
    } catch (e) {
      return PythonResult.failure(error: e.toString());
    }
  }

  /// Checks if Python is available on the platform.
  Future<bool> isPythonAvailable() async {
    try {
      if (Platform.isAndroid) {
        try {
          final result = await _channel.invokeMethod('isPythonAvailable');
          if (result == true) {
            return true;
          }
        } catch (e) {
          // Fall back to checking with the executor
        }
      }
      
      // Check if Python is available using a simple command
      final pythonExecutable = Platform.isWindows ? 'python' : 'python3';
      
      try {
        final result = await Process.run(
          pythonExecutable,
          ['--version'],
        );
        
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Gets the Python version from the platform-specific implementation if available,
  /// otherwise falls back to the generic approach.
  Future<String?> getPythonVersion() async {
    try {
      if (Platform.isAndroid) {
        try {
          final result = await _channel.invokeMethod('getPythonVersion');
          if (result != null && result is String) {
            return result;
          }
        } catch (e) {
          // Fall back to checking with the executor
        }
      }
      
      // Get Python version using a simple command
      final pythonExecutable = Platform.isWindows ? 'python' : 'python3';
      
      try {
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
    } catch (e) {
      return null;
    }
  }

  /// Invokes a method on the platform channel.
  /// 
  /// This is a generic method to invoke any method on the platform channel.
  /// It's used internally by other methods in this class.
  Future<dynamic> invokeMethod(String method, [Map<String, dynamic>? arguments]) async {
    try {
      return await _channel.invokeMethod(method, arguments);
    } catch (e) {
      throw Exception('Failed to invoke method $method: $e');
    }
  }
}
