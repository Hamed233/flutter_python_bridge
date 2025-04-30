import 'package:flutter/material.dart';
import 'package:flutter_python_bridge/flutter_python_bridge.dart';
import 'advanced_example.dart';
import 'ml_example.dart';
import 'nlp_example.dart';
import 'image_processing_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Python Bridge Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MyHomePage(title: 'Flutter Python Bridge Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final PythonBridge _pythonBridge = PythonBridge();
  final TextEditingController _codeController = TextEditingController();
  String _output = '';
  bool _isLoading = false;
  bool _isPythonAvailable = false;
  String? _pythonVersion;

  @override
  void initState() {
    super.initState();
    _checkPythonAvailability();
    _codeController.text = _getDefaultPythonCode();
  }

  Future<void> _checkPythonAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isPythonAvailable = await _pythonBridge.isPythonAvailable();
      final pythonVersion = await _pythonBridge.getPythonVersion();

      setState(() {
        _isPythonAvailable = isPythonAvailable;
        _pythonVersion = pythonVersion;
      });
    } catch (e) {
      setState(() {
        _output = 'Error checking Python availability: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runPythonCode() async {
    setState(() {
      _isLoading = true;
      _output = '';
    });

    try {
      final result = await _pythonBridge.runCode(_codeController.text);

      setState(() {
        if (result.success) {
          _output = '${result.output ?? "No output"}';
          if (result.returnValue != null) {
            _output += '\n\nReturn Value: ${result.returnValue}';
          }
        } else {
          _output = 'Error:\n${result.error ?? "Unknown error"}';
          if (result.output != null && result.output!.isNotEmpty) {
            _output += '${result.output}';
          }
        }

        print(_output);
      });
    } catch (e) {
      setState(() {
        _output = 'Exception: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDefaultPythonCode() {
    return '''# Example Python code
import math
from datetime import datetime

# Define a function
def calculate_circle_area(radius):
    return math.pi * radius ** 2

# Get current date and time
now = datetime.now()
print(f"Current date and time: {now}")

# Calculate area of a circle with radius 5
radius = 5
area = calculate_circle_area(radius)
print(f"Area of circle with radius {radius} is {area:.2f}")

# Create a list and perform operations
numbers = [1, 2, 3, 4, 5]
sum_of_numbers = sum(numbers)
print(f"Sum of {numbers} is {sum_of_numbers}")

# Return a dictionary with results
{
    "circle_area": area,
    "sum": sum_of_numbers,
    "timestamp": str(now)
}
''';
  }

  void _navigateToExample(Widget example) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => example));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Flutter Python Bridge',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Python Available: ${_isPythonAvailable ? "Yes" : "No"}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  // if (_pythonVersion != null)
                  //   Text(
                  //     'Version: $_pythonVersion',
                  //     style: const TextStyle(color: Colors.white),
                  //   ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Basic Python Example'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Data Analysis Example'),
              onTap: () {
                Navigator.pop(context);
                _navigateToExample(const AdvancedExamplePage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('Machine Learning Example'),
              onTap: () {
                Navigator.pop(context);
                _navigateToExample(const MLExamplePage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('NLP Example'),
              onTap: () {
                Navigator.pop(context);
                _navigateToExample(const NLPExamplePage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Image Processing Example'),
              onTap: () {
                Navigator.pop(context);
                _navigateToExample(const ImageProcessingExamplePage());
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Python status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Python Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Python Available: '),
                        _isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Text(
                              _isPythonAvailable ? 'Yes' : 'No',
                              style: TextStyle(
                                color:
                                    _isPythonAvailable
                                        ? Colors.green
                                        : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ],
                    ),
                    if (_pythonVersion != null) ...[
                      const SizedBox(height: 4),
                      Text('Python Version: $_pythonVersion'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Code editor
            Text(
              'Python Code:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _codeController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Run button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _runPythonCode,
              icon: const Icon(Icons.play_arrow),
              label: Text(_isLoading ? 'Running...' : 'Run Python Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Output
            Text('Output:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: SingleChildScrollView(child: Text(_output)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
