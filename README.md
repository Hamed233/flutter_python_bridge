# Flutter Python Bridge

<img src="/images/flutter_python_bridge.png" alt="flutter_python_bridge" width="800" style="max-width: 100%;">

[![pub package](https://img.shields.io/pub/v/flutter_python_bridge.svg)](https://pub.dev/packages/flutter_python_bridge)

A powerful Flutter library that enables running Python code directly in Flutter applications. This package provides a seamless bridge between Flutter and Python, allowing you to leverage Python's extensive ecosystem of libraries for machine learning, data analysis, image processing, and more.

## Demo
🎥 [Watch Demo Video](https://vimeo.com/1080106510/6bcb8a6fa2?share=copy)

## Features

- **Run Python code** directly from Flutter
- **Execute Python script files**
- **Install Python packages** at runtime (where supported)
- **Machine Learning** with scikit-learn, TensorFlow, etc.
- **Data Analysis** with pandas, numpy, matplotlib
- **Image Processing** with OpenCV
- **Cross-platform support** with optimized implementations
- **Android optimization** via Chaquopy integration

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_python_bridge: ^0.1.0
```

### Android Setup

For Android, this library uses [Chaquopy](https://chaquo.com/chaquopy/) to run Python code. Configure your Android project:

1. Add the Chaquopy Gradle plugin to your app's `android/build.gradle` file:

```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
        maven { url "https://chaquo.com/maven" }
    }
    dependencies {
        classpath "com.chaquo.python:gradle:13.0.0"
    }
}
```

2. Apply the Chaquopy plugin in your app-level `android/app/build.gradle`:

```gradle
apply plugin: "com.chaquo.python"

android {
    defaultConfig {
        ndk {
            abiFilters "armeabi-v7a", "arm64-v8a", "x86", "x86_64"
        }
        python {
            version "3.8"
            pip {
                // Add your required Python packages here
                install "numpy"
                install "pandas"
                install "matplotlib"
                install "scikit-learn"
                install "opencv-python"
                install "pillow"
            }
        }
    }
}
```

> **Important Note for Android**: Due to Chaquopy limitations, Python packages must be bundled at build time. Runtime installation of packages not included in the build.gradle will not work on Android.

### iOS/Desktop Setup

For iOS and desktop platforms, this library uses the system Python. Ensure Python 3.6+ is installed on your development machine.

## Basic Usage

### Running Python Code

```dart
import 'package:flutter_python_bridge/flutter_python_bridge.dart';

// Create a Python bridge instance
final pythonBridge = PythonBridge();

// Run simple Python code
Future<void> runPythonExample() async {
  final result = await pythonBridge.runCode('''
import numpy as np

def calculate_mean(numbers):
    return np.mean(numbers)

result = calculate_mean([1, 2, 3, 4, 5])
print(f"The mean is: {result}")
''');

  if (result.success) {
    print('Output: ${result.output}');
  } else {
    print('Error: ${result.error}');
  }
}
```

### Running a Python Script File

```dart
// Run a Python script file
Future<void> runPythonScript() async {
  final result = await pythonBridge.runScript('/path/to/script.py');

  if (result.success) {
    print('Output: ${result.output}');
  } else {
    print('Error: ${result.error}');
  }
}
```

### Installing Python Packages

```dart
// Install a Python package (works on desktop, limited on Android)
Future<void> installPackage() async {
  final result = await pythonBridge.installPackage('matplotlib');

  if (result.success) {
    print('Package installed successfully');
  } else {
    print('Failed to install package: ${result.error}');
  }
}
```

## Advanced Examples

### Data Analysis with Pandas and Matplotlib

```dart
Future<void> runDataAnalysis() async {
  // Create a temporary directory for output files
  final tempDir = await getTemporaryDirectory();
  final outputDir = Directory(path.join(tempDir.path, 'python_output'));
  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }
  
  final plotPath = path.join(outputDir.path, 'plot.png');
  
  final pythonCode = '''
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns

# Create sample data
data = {
    'Category': ['A', 'B', 'C', 'D', 'E'],
    'Values': [5, 7, 3, 9, 6]
}

# Create a DataFrame
df = pd.DataFrame(data)

# Create a plot
plt.figure(figsize=(10, 6))
sns.barplot(x='Category', y='Values', data=df)
plt.title('Sample Bar Plot')
plt.tight_layout()

# Save the plot
plt.savefig('${plotPath.replaceAll('\\', '/')}')
print(f"Plot saved to {plotPath}")

# Return some statistics
stats = df.describe().to_dict()
print(stats)
''';

  final result = await pythonBridge.runCode(pythonCode);
  
  if (result.success) {
    print('Analysis complete. Plot saved at: $plotPath');
  }
}
```

### Machine Learning with Scikit-Learn

```dart
Future<void> runMachineLearning() async {
  final features = [5.1, 3.5, 1.4, 0.2]; // Example iris flower features
  final featuresStr = features.map((f) => f.toString()).join(', ');
  
  final pythonCode = '''
import numpy as np
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier

# Load the Iris dataset
iris = load_iris()
X = iris.data
y = iris.target
feature_names = iris.feature_names
target_names = iris.target_names

# Train a Random Forest classifier
rf = RandomForestClassifier(n_estimators=100, random_state=42)
rf.fit(X, y)

# Make a prediction for the input features
input_features = np.array([[${featuresStr}]])  # Properly formatted as 2D array
print(f"Input features: {input_features[0]}")

# Predict the class
prediction = rf.predict(input_features)[0]
predicted_class = target_names[prediction]
print(f"Predicted class: {predicted_class}")

# Get class probabilities
probabilities = rf.predict_proba(input_features)[0]
class_probability = probabilities[prediction]
print(f"Probability: {class_probability:.4f}")
''';

  final result = await pythonBridge.runCode(pythonCode);
  
  if (result.success) {
    print('ML prediction output: ${result.output}');
  }
}
```

### Image Processing with OpenCV

```dart
Future<void> processImage(String imagePath) async {
  final imageProcessor = ImageProcessor();
  
  // Define image operations
  final operations = [
    GrayscaleOperation(),
    BlurOperation(kernelSize: 5),
    EdgeDetectionOperation(threshold1: 100, threshold2: 200),
  ];
  
  // Process the image and save to assets folder
  final result = await imageProcessor.processImage(
    imagePath,
    operations,
    saveToAssets: true, // Save to assets folder instead of cache
  );
  
  if (result.success) {
    final processedImagePath = result.returnValue as String?;
    print('Image processed and saved to: $processedImagePath');
  } else {
    print('Error processing image: ${result.error}');
  }
}
```

### iOS and Web Limitations

Due to platform restrictions, running Python directly within iOS apps or web applications is not possible:

#### iOS Limitations

iOS's sandboxing model prevents apps from:

1. Launching external processes (like Python)
2. Installing software at runtime
3. Executing arbitrary code outside the app sandbox

#### Web Limitations

Web applications run in a browser sandbox that prevents:

1. Direct access to the file system
2. Launching external processes
3. Running native code like Python

#### Alternatives for iOS and Web

If you need Python functionality in an iOS app or web application, consider these alternatives:

1. **Backend Service**: Create a Python API backend that your app can call
2. **Feature Detection**: Detect the platform and disable Python features on unsupported platforms
3. **WebAssembly** (Experimental): For some use cases, libraries like Pyodide might help run Python code via WebAssembly

```dart
// Example of platform-specific code
import 'dart:io' if (dart.library.html) 'package:flutter_python_bridge/src/web_stub.dart';

// Check platform
if (Platform.isIOS || Platform.isWeb) {
  // Show alternative UI or use a backend service
} else {
  // Use Flutter Python Bridge directly
  final result = await pythonBridge.runCode(pythonCode);
}
```

## Available Image Operations

The `ImageProcessor` class supports various image operations:

- `GrayscaleOperation()` - Convert image to grayscale
- `BlurOperation(kernelSize: 5)` - Apply Gaussian blur
- `EdgeDetectionOperation(threshold1: 100, threshold2: 200)` - Detect edges using Canny algorithm
- `BrightnessContrastOperation(brightness: 30, contrast: 1.2)` - Adjust brightness and contrast
- `RotateOperation(angle: 45)` - Rotate image by specified angle
- `FlipOperation(horizontal: true, vertical: false)` - Flip image horizontally or vertically
- `CropOperation(x: 100, y: 100, width: 300, height: 300)` - Crop image to specified region
- `ResizeOperation(width: 800, height: 600)` - Resize image to specified dimensions

## Platform-Specific Considerations

### Android

- Uses Chaquopy for Python execution
- Python packages must be included in the `build.gradle` file
- Runtime package installation is limited to packages already included in the build

### iOS/Desktop

- Uses system Python interpreter
- Supports runtime package installation
- Requires Python to be installed on the system

## Error Handling

All methods return a `PythonResult` object that contains:

- `success`: Boolean indicating if the operation was successful
- `output`: String containing the standard output from Python
- `error`: String containing any error message (if `success` is false)
- `returnValue`: Optional value returned from the operation

## Troubleshooting

### Android Issues

- **Missing Python packages**: Ensure all required packages are listed in your `build.gradle` file
- **Runtime pip install fails**: Remember that Chaquopy does not support `ensurepip` and runtime pip installs are limited

### iOS/Desktop Issues

- **Python not found**: Ensure Python 3.6+ is installed and in your PATH
- **Package installation fails**: Check internet connectivity and package name spelling

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
