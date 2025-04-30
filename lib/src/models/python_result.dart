/// Represents the result of a Python code execution.
class PythonResult {
  /// Whether the execution was successful
  final bool success;
  
  /// The output of the Python code execution
  final String? output;
  
  /// Any error message if the execution failed
  final String? error;
  
  /// Any returned value from the Python code
  final dynamic returnValue;

  /// Creates a new [PythonResult] instance.
  const PythonResult({
    required this.success,
    this.output,
    this.error,
    this.returnValue,
  });

  /// Creates a successful result.
  factory PythonResult.success({String? output, dynamic returnValue}) {
    return PythonResult(
      success: true,
      output: output,
      returnValue: returnValue,
    );
  }

  /// Creates a failed result.
  factory PythonResult.failure({String? error, String? output}) {
    return PythonResult(
      success: false,
      error: error,
      output: output,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'PythonResult(success: true, output: $output, returnValue: $returnValue)';
    } else {
      return 'PythonResult(success: false, error: $error, output: $output)';
    }
  }
}
