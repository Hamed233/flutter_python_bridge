import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_python_bridge/flutter_python_bridge.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AdvancedExamplePage extends StatefulWidget {
  const AdvancedExamplePage({Key? key}) : super(key: key);

  @override
  State<AdvancedExamplePage> createState() => _AdvancedExamplePageState();
}

class _AdvancedExamplePageState extends State<AdvancedExamplePage> {
  final PythonBridge _pythonBridge = PythonBridge();
  bool _isLoading = false;
  String _output = '';
  String? _imagePath;
  Map<String, dynamic>? _analysisResults;

  String _getPythonCode() {
    return '''import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import json
import os
from sklearn.datasets import load_iris

# Create output directory if it doesn't exist
output_dir = os.path.join(os.path.expanduser('~'), 'python_output')
if not os.path.exists(output_dir):
    os.makedirs(output_dir, exist_ok=True)

# Define plot file path
plot_file = os.path.join(output_dir, 'data_plot.png')

# Load the Iris dataset
iris = load_iris()
df = pd.DataFrame(iris.data, columns=iris.feature_names)

# Add the target column
df['species'] = [iris.target_names[t] for t in iris.target]

# Basic statistics
stats = df.describe()

# Correlation matrix
corr_matrix = df.iloc[:, :4].corr()

# Create a visualization
plt.figure(figsize=(12, 10))

# Create a pairplot
sns.pairplot(df, hue='species', markers=['o', 's', 'D'])
plt.suptitle('Iris Dataset Pairplot', y=1.02)
plt.savefig(plot_file)
print(f"Plot saved to {plot_file}")

# Create a heatmap of the correlation matrix
plt.figure(figsize=(10, 8))
sns.heatmap(corr_matrix, annot=True, cmap='coolwarm')
plt.title('Correlation Matrix')

# Prepare results to return to Flutter
results = {
    'mean': stats.loc['mean'].to_dict(),
    'median': df.median().to_dict(),
    'std': stats.loc['std'].to_dict(),
    'min': stats.loc['min'].to_dict(),
    'max': stats.loc['max'].to_dict(),
    'correlation_matrix': corr_matrix.to_dict(),
    'plot_path': plot_file
}

# Print the results as JSON so we can parse them in Flutter
print(json.dumps(results))
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Python Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Python code section
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
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Text(
                    _getPythonCode(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _runDataAnalysis,
              child: Text(_isLoading ? 'Processing...' : 'Run Data Analysis'),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_analysisResults != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analysis Results',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text('Mean: ${_analysisResults!['mean']}'),
                              Text('Median: ${_analysisResults!['median']}'),
                              Text(
                                'Standard Deviation: ${_analysisResults!['std']}',
                              ),
                              Text('Min: ${_analysisResults!['min']}'),
                              Text('Max: ${_analysisResults!['max']}'),
                              const SizedBox(height: 8),
                              Text('Correlation Matrix:'),
                              Text(
                                _analysisResults!['correlation_matrix']
                                    .toString(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_imagePath != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data Visualization',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Image.file(File(_imagePath!)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Python Output',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(_output),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runDataAnalysis() async {
    setState(() {
      _isLoading = true;
      _output = 'Running data analysis...';
      _imagePath = null;
      _analysisResults = null;
    });

    try {
      // Create and run the Python script
      final pythonCode = _getPythonCode();

      final result = await _pythonBridge.runCode(pythonCode);

      if (result.success) {
        setState(() {
          _output = result.output ?? 'No output';

          // Try to parse the JSON results
          try {
            final jsonStart = _output.indexOf('{');
            final jsonEnd = _output.lastIndexOf('}') + 1;
            if (jsonStart >= 0 && jsonEnd > jsonStart) {
              final jsonStr = _output.substring(jsonStart, jsonEnd);
              _analysisResults = json.decode(jsonStr);

              // Check if the plot file was created
              final plotPath = _analysisResults!['plot_path'];
              if (plotPath != null) {
                _imagePath = plotPath;
              }
            }
          } catch (e) {
            print('Error parsing JSON results: $e');
          }
        });
      } else {
        setState(() {
          _output = 'Error: ${result.error ?? "Unknown error"}';
        });
      print(_output);

      }
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
}
