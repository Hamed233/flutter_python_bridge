import 'dart:async';
import 'dart:io';

import 'package:flutter_python_bridge/src/models/python_result.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/process_run.dart';
import 'package:path/path.dart' as path;

/// A class that handles the execution of Python code.
class PythonExecutor {
  /// Path to the Python executable
  final String? pythonExecutablePath;
  
  /// Additional Python paths to add to PYTHONPATH
  final List<String> additionalPythonPaths;

  /// Creates a new [PythonExecutor] instance.
  PythonExecutor({
    this.pythonExecutablePath,
    this.additionalPythonPaths = const [],
  });

  /// Executes Python code and returns the result.
  Future<PythonResult> executeCode(String pythonCode) async {
    try {
      // Create a temporary Python file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(tempDir.path, 'flutter_python_${DateTime.now().millisecondsSinceEpoch}.py'));
      await tempFile.writeAsString(pythonCode);

      // Prepare environment variables
      final env = Map<String, String>.from(Platform.environment);
      if (additionalPythonPaths.isNotEmpty) {
        final pythonPath = additionalPythonPaths.join(Platform.isWindows ? ';' : ':');
        env['PYTHONPATH'] = env.containsKey('PYTHONPATH')
            ? '${env['PYTHONPATH']}${Platform.isWindows ? ';' : ':'}$pythonPath'
            : pythonPath;
      }

      // Execute the Python file
      final pythonExecutable = pythonExecutablePath ?? _detectPythonExecutable();
      
      ProcessResult result;
      try {
        result = await Process.run(
          pythonExecutable,
          [tempFile.path],
          environment: env,
        );
      } catch (e) {
        // If direct execution fails, try using process_run as a fallback
        result = await runExecutableArguments(
          pythonExecutable,
          [tempFile.path],
          environment: env,
          includeParentEnvironment: true,
        );
      }

      // Clean up the temporary file
      await tempFile.delete();

      if (result.exitCode == 0) {
        return PythonResult.success(output: result.stdout.toString().trim());
      } else {
        return PythonResult.failure(
          error: result.stderr.toString().trim(),
          output: result.stdout.toString().trim(),
        );
      }
    } catch (e) {
      return PythonResult.failure(error: e.toString());
    }
  }

  /// Executes a Python script file and returns the result.
  Future<PythonResult> executeFile(String filePath) async {
    try {
      // Check if the file exists
      final file = File(filePath);
      if (!await file.exists()) {
        return PythonResult.failure(error: 'Python script file not found: $filePath');
      }

      // Prepare environment variables
      final env = Map<String, String>.from(Platform.environment);
      if (additionalPythonPaths.isNotEmpty) {
        final pythonPath = additionalPythonPaths.join(Platform.isWindows ? ';' : ':');
        env['PYTHONPATH'] = env.containsKey('PYTHONPATH')
            ? '${env['PYTHONPATH']}${Platform.isWindows ? ';' : ':'}$pythonPath'
            : pythonPath;
      }

      // Execute the Python file
      final pythonExecutable = pythonExecutablePath ?? _detectPythonExecutable();
      
      ProcessResult result;
      try {
        result = await Process.run(
          pythonExecutable,
          [filePath],
          environment: env,
        );
      } catch (e) {
        // If direct execution fails, try using process_run as a fallback
        result = await runExecutableArguments(
          pythonExecutable,
          [filePath],
          environment: env,
          includeParentEnvironment: true,
        );
      }

      if (result.exitCode == 0) {
        return PythonResult.success(output: result.stdout.toString().trim());
      } else {
        return PythonResult.failure(
          error: result.stderr.toString().trim(),
          output: result.stdout.toString().trim(),
        );
      }
    } catch (e) {
      return PythonResult.failure(error: e.toString());
    }
  }

  /// Installs a Python package using pip.
  /// 
  /// This method uses the system's pip to install a Python package.
  Future<PythonResult> installPackage(String packageName) async {
    try {
      // Prepare environment variables
      final env = Map<String, String>.from(Platform.environment);
      if (additionalPythonPaths.isNotEmpty) {
        final pythonPath = additionalPythonPaths.join(Platform.isWindows ? ';' : ':');
        env['PYTHONPATH'] = env.containsKey('PYTHONPATH')
            ? '${env['PYTHONPATH']}${Platform.isWindows ? ';' : ':'}$pythonPath'
            : pythonPath;
      }

      // Get the Python executable
      final pythonExecutable = pythonExecutablePath ?? _detectPythonExecutable();
      
      // Try to install the package
      ProcessResult result;
      try {
        // First try direct Process.run
        result = await Process.run(
          pythonExecutable,
          ['-m', 'pip', 'install', packageName],
          environment: env,
        );
      } catch (e) {
        // If direct execution fails, try a different approach
        try {
          // Try with subprocess call
          result = await Process.run(
            'pip',
            ['install', packageName],
            environment: env,
          );
        } catch (pipError) {
          // Last resort: try system python -m pip
          result = await Process.run(
            'python',
            ['-m', 'pip', 'install', packageName],
            environment: env,
          );
        }
      }
      
      // Check if the installation was successful
      if (result.exitCode == 0) {
        // Try to import the package to verify it was installed
        final basePackageName = packageName.split('[<>=!~]')[0].trim();
        
        try {
          // Create a temporary Python file to test the import
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(path.join(tempDir.path, 'test_import_${DateTime.now().millisecondsSinceEpoch}.py'));
          await tempFile.writeAsString('''
          try:
              import $basePackageName
              print("Package successfully imported")
          except ImportError as e:
              print(f"Import error: {e}")
          ''');
          
          // Run the test import
          final importResult = await Process.run(
            pythonExecutable,
            [tempFile.path],
            environment: env,
          );
          
          // Clean up the temporary file
          await tempFile.delete();
          
          return PythonResult(
            success: true,
            output: 'Successfully installed $packageName\n${result.stdout}',
            error: result.stderr.toString(),
            returnValue: importResult.stdout.toString().contains('successfully imported') 
                ? 'Package successfully installed and imported' 
                : 'Package installed but import test failed: ${importResult.stdout}',
          );
        } catch (importError) {
          // If the import test fails, still return success since the package was installed
          return PythonResult(
            success: true,
            output: 'Successfully installed $packageName\n${result.stdout}',
            error: result.stderr.toString(),
            returnValue: 'Package installed but import test failed: $importError',
          );
        }
      } else {
        return PythonResult(
          success: false,
          output: result.stdout.toString(),
          error: 'Failed to install $packageName: ${result.stderr}',
        );
      }
    } catch (e) {
      return PythonResult(
        success: false,
        error: 'Exception while installing $packageName: $e',
      );
    }
  }

  /// Detects the Python executable path based on the platform.
  String _detectPythonExecutable() {
    if (Platform.isWindows) {
      return 'python';
    } else if (Platform.isAndroid) {
      // On Android, we need to check if Python is available in a specific location
      // This is just a placeholder - actual Android implementation would need more work
      return 'python3';
    } else {
      return 'python3';
    }
  }
}
