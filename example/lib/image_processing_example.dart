import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_python_bridge/flutter_python_bridge.dart';
import 'package:flutter_python_bridge/src/image_processor.dart';
import 'package:image_picker/image_picker.dart';

class ImageProcessingExamplePage extends StatefulWidget {
  const ImageProcessingExamplePage({Key? key}) : super(key: key);

  @override
  State<ImageProcessingExamplePage> createState() => _ImageProcessingExamplePageState();
}

class _ImageProcessingExamplePageState extends State<ImageProcessingExamplePage> {
  final ImageProcessor _imageProcessor = ImageProcessor();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  String _output = '';
  String? _originalImagePath;
  String? _processedImagePath;
  List<ImageOperation> _selectedOperations = [];
  bool _showCode = false;

  String _getPythonCode() {
    if (_originalImagePath == null || _selectedOperations.isEmpty) {
      return 'Select an image and at least one operation to view the Python code.';
    }

    return _imageProcessor.generateImageProcessingCode(
      inputPath: _originalImagePath!,
      outputPath: 'output_path_placeholder.jpg',
      operations: _selectedOperations,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Processing with Python'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Select Image'),
            ),
            const SizedBox(height: 16),
            if (_originalImagePath != null) ...[
              const Text('Image Operations:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildOperationChip('Grayscale', GrayscaleOperation()),
                  _buildOperationChip('Blur', BlurOperation()),
                  _buildOperationChip('Edge Detection', EdgeDetectionOperation()),
                  _buildOperationChip('Brighten', BrightnessContrastOperation(brightness: 30, contrast: 1.2)),
                  _buildOperationChip('Rotate 90°', RotateOperation(angle: 90)),
                  _buildOperationChip('Flip Horizontal', FlipOperation(flipCode: 1)),
                ],
              ),
              const SizedBox(height: 16),
              // Python code section with toggle
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
              if (_showCode && _selectedOperations.isNotEmpty)
                Container(
                  height: 200,
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
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _selectedOperations.isEmpty || _isLoading ? null : _processImage,
                icon: const Icon(Icons.auto_fix_high),
                label: Text(_isLoading ? 'Processing...' : 'Process Image'),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_originalImagePath != null && _processedImagePath != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Original', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Image.file(
                                  File(_originalImagePath!),
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Processed', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Image.file(
                                  File(_processedImagePath!),
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else if (_originalImagePath != null) ...[
                      Image.file(
                        File(_originalImagePath!),
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ],
                    if (_output.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Python Output:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_output),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationChip(String label, ImageOperation operation) {
    final isSelected = _selectedOperations.any((op) => op.runtimeType == operation.runtimeType);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedOperations.add(operation);
          } else {
            _selectedOperations.removeWhere((op) => op.runtimeType == operation.runtimeType);
          }
        });
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _originalImagePath = pickedFile.path;
          _processedImagePath = null;
          _output = '';
          _selectedOperations = [];
        });
      }
    } catch (e) {
      setState(() {
        _output = 'Error picking image: $e';
      });
    }
  }

  Future<void> _processImage() async {
    if (_originalImagePath == null || _selectedOperations.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _output = 'Processing image...';
      _processedImagePath = null;
    });

    try {
      final result = await _imageProcessor.processImage(
        _originalImagePath!,
        _selectedOperations,
        saveToAssets: false, // Use home directory instead of assets folder
      );

      setState(() {
        if (result.success) {
          _processedImagePath = result.returnValue as String?;
          _output = result.output ?? 'Image processed successfully';
          if (_processedImagePath != null) {
            _output += '\n\nImage saved to: $_processedImagePath';
          }
        } else {
          _output = 'Error: ${result.error ?? "Unknown error"}';
        }
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
}
