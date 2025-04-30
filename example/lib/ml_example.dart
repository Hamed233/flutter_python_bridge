import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_python_bridge/flutter_python_bridge.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MLExamplePage extends StatefulWidget {
  const MLExamplePage({Key? key}) : super(key: key);

  @override
  State<MLExamplePage> createState() => _MLExamplePageState();
}

class _MLExamplePageState extends State<MLExamplePage> {
  final PythonBridge _pythonBridge = PythonBridge();
  bool _isLoading = false;
  String _output = '';
  List<String> _imagePaths = [];
  Map<String, dynamic>? _mlResults;
  final List<double> _features = [5.1, 3.5, 1.4, 0.2]; // Default sepal length, sepal width, petal length, petal width
  bool _showCode = false;

  final List<TextEditingController> _featureControllers = [
    TextEditingController(text: '5.1'), // sepal length
    TextEditingController(text: '3.5'), // sepal width
    TextEditingController(text: '1.4'), // petal length
    TextEditingController(text: '0.2'), // petal width
  ];

  @override
  void initState() {
    super.initState();
    // Update the features list when text controllers change
    for (int i = 0; i < _featureControllers.length; i++) {
      _featureControllers[i].addListener(() {
        try {
          _features[i] = double.parse(_featureControllers[i].text);
        } catch (e) {
          // Handle parsing errors
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _featureControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getPythonCode() {
    final featuresStr = _featureControllers.map((controller) {
      return double.tryParse(controller.text) ?? 0.0;
    }).toList().map((f) => f.toString()).join(', ');

    return '''import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import json
import os
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score

# Create output directory if it doesn't exist
output_dir = os.path.join(os.path.expanduser('~'), 'python_ml_output')
if not os.path.exists(output_dir):
    os.makedirs(output_dir, exist_ok=True)

# Set the paths for output files
decision_boundary_path = os.path.join(output_dir, 'decision_boundary.png')
feature_importance_path = os.path.join(output_dir, 'feature_importance.png')

# Load the Iris dataset
iris = load_iris()
X = iris.data
y = iris.target
feature_names = iris.feature_names
target_names = iris.target_names

# Split the data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

# Train a Random Forest classifier
rf = RandomForestClassifier(n_estimators=100, random_state=42)
rf.fit(X_train, y_train)

# Make predictions on the test set
y_pred = rf.predict(X_test)

# Calculate accuracy
accuracy = accuracy_score(y_test, y_pred)
print(f"Model accuracy: {accuracy:.4f}")

# Get feature importances
importances = rf.feature_importances_
indices = np.argsort(importances)[::-1]

print("Feature ranking:")
for i in range(X.shape[1]):
    print(f"{i+1}. {feature_names[indices[i]]} ({importances[indices[i]]:.4f})")

# Plot feature importances
plt.figure(figsize=(10, 6))
plt.title("Feature Importances")
plt.bar(range(X.shape[1]), importances[indices], align="center")
plt.xticks(range(X.shape[1]), [feature_names[i] for i in indices], rotation=90)
plt.tight_layout()
plt.savefig(feature_importance_path)
plt.close()
print(f"Feature importance plot saved to {feature_importance_path}")

# Function to create a decision boundary plot
def plot_decision_boundary():
    # Use the two most important features
    feature_idx1, feature_idx2 = indices[0], indices[1]
    
    # Create a mesh grid
    h = 0.02  # Step size
    x_min, x_max = X[:, feature_idx1].min() - 1, X[:, feature_idx1].max() + 1
    y_min, y_max = X[:, feature_idx2].min() - 1, X[:, feature_idx2].max() + 1
    xx, yy = np.meshgrid(np.arange(x_min, x_max, h), np.arange(y_min, y_max, h))
    
    # Create feature array with all other features set to their mean
    mesh_features = np.zeros((xx.ravel().shape[0], X.shape[1]))
    for i in range(X.shape[1]):
        if i == feature_idx1:
            mesh_features[:, i] = xx.ravel()
        elif i == feature_idx2:
            mesh_features[:, i] = yy.ravel()
        else:
            mesh_features[:, i] = X[:, i].mean()
    
    # Predict class for each point in the mesh
    Z = rf.predict(mesh_features)
    Z = Z.reshape(xx.shape)
    
    # Plot the decision boundary
    plt.figure(figsize=(10, 8))
    plt.contourf(xx, yy, Z, alpha=0.8, cmap=plt.cm.Spectral)
    
    # Plot the training points
    for i, color in zip(range(len(target_names)), ['red', 'green', 'blue']):
        idx = np.where(y == i)
        plt.scatter(X[idx, feature_idx1], X[idx, feature_idx2], 
                    c=color, label=target_names[i], edgecolors='black')
    
    plt.xlabel(feature_names[feature_idx1])
    plt.ylabel(feature_names[feature_idx2])
    plt.title('Decision Boundary')
    plt.legend()
    plt.savefig(decision_boundary_path)
    plt.close()
    print(f"Decision boundary plot saved to {decision_boundary_path}")

# Create the decision boundary plot
plot_decision_boundary()

# Predict the class for the input features
input_features = np.array([${featuresStr}])
print(f"Input features: {input_features}")

# Get the prediction and probability
prediction = rf.predict([input_features])[0]
probabilities = rf.predict_proba([input_features])[0]
prediction_probability = probabilities[prediction]

print(f"Predicted class: {target_names[prediction]}")
print(f"Probability: {prediction_probability:.4f}")

# Prepare results to return to Flutter
results = {
    'prediction': target_names[prediction],
    'probability': float(prediction_probability),
    'accuracy': float(accuracy),
    'feature_importance': [
        {'name': feature_names[indices[i]], 'importance': float(importances[indices[i]])}
        for i in range(len(feature_names))
    ],
    'decision_boundary_path': decision_boundary_path,
    'feature_importance_path': feature_importance_path
}

# Print the results as JSON so we can parse them in Flutter
print(json.dumps(results))
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML with Python Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Iris Flower Prediction',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _featureControllers[0],
                            decoration: const InputDecoration(
                              labelText: 'Sepal Length',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _featureControllers[1],
                            decoration: const InputDecoration(
                              labelText: 'Sepal Width',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _featureControllers[2],
                            decoration: const InputDecoration(
                              labelText: 'Petal Length',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _featureControllers[3],
                            decoration: const InputDecoration(
                              labelText: 'Petal Width',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Python Code:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton.icon(
                          icon: Icon(_showCode ? Icons.visibility_off : Icons.visibility),
                          label: Text(_showCode ? 'Hide Code' : 'Show Code'),
                          onPressed: () {
                            setState(() {
                              _showCode = !_showCode;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_showCode)
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
                      onPressed: _isLoading ? null : _runMachineLearning,
                      child: Text(_isLoading ? 'Processing...' : 'Predict Flower Type'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_mlResults != null) ...[  
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prediction Results',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Predicted Flower: ${_mlResults!['prediction']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Text('Probability: ${(_mlResults!['probability'] * 100).toStringAsFixed(2)}%'),
                              const SizedBox(height: 8),
                              Text('Model Accuracy: ${(_mlResults!['accuracy'] * 100).toStringAsFixed(2)}%'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_imagePaths.isNotEmpty) ...[  
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Model Visualization',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              for (var imagePath in _imagePaths)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Image.file(File(imagePath)),
                                ),
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

  Future<void> _runMachineLearning() async {
    setState(() {
      _isLoading = true;
      _output = 'Running machine learning model...';
      _imagePaths = [];
      _mlResults = null;
    });

    try {
      // Create and run the Python script for machine learning
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
              _mlResults = json.decode(jsonStr);
              
              // Get the image paths from the results
              if (_mlResults!.containsKey('decision_boundary_path')) {
                _imagePaths.add(_mlResults!['decision_boundary_path']);
              }
              
              if (_mlResults!.containsKey('feature_importance_path')) {
                _imagePaths.add(_mlResults!['feature_importance_path']);
              }
            }
          } catch (e) {
            print('Error parsing JSON results: $e');
          }
        });
      } else {
        setState(() {
          _output = 'Error: ${result.error}';
        });
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
