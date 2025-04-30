/// Web stub for dart:io Platform
/// This provides stub implementations of the Platform class for web

import 'dart:convert';

class Platform {
  /// Returns false for web
  static bool get isAndroid => false;
  
  /// Returns false for web
  static bool get isIOS => false;
  
  /// Returns false for web
  static bool get isMacOS => false;
  
  /// Returns false for web
  static bool get isWindows => false;
  
  /// Returns false for web
  static bool get isLinux => false;
  
  /// Returns true for web
  static bool get isWeb => true;
  
  /// Empty map for web
  static Map<String, String> get environment => {};
}

/// Web stub for dart:io File
class File {
  final String path;
  
  /// Constructor that takes a path
  File(this.path);
  
  /// Always returns false on web
  Future<bool> exists() async => false;
  
  /// Throws unsupported error on web
  Future<File> writeAsString(String contents) async {
    throw UnsupportedError('File operations are not supported on web platforms');
  }
  
  /// Throws unsupported error on web
  Future<String> readAsString() async {
    throw UnsupportedError('File operations are not supported on web platforms');
  }
}

/// Web stub for dart:io Process
class Process {
  /// Throws unsupported error on web
  static Future<ProcessResult> run(
    String executable,
    List<String> arguments,
    {String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding = systemEncoding,
    Encoding? stderrEncoding = systemEncoding}) async {
    throw UnsupportedError('Process operations are not supported on web platforms');
  }
}

/// Web stub for ProcessResult
class ProcessResult {
  final int pid;
  final int exitCode;
  final String stdout;
  final String stderr;
  
  ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}

/// Web stub for system encoding
const Encoding systemEncoding = Utf8Codec();

/// Web stub for Encoding
class Encoding {
  const Encoding();
}

/// Web stub for Utf8Codec
class Utf8Codec extends Encoding {
  const Utf8Codec();
}
