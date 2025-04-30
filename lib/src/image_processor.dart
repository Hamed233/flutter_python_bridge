import 'dart:convert';
import 'dart:io';

import 'package:flutter_python_bridge/src/models/python_result.dart';
import 'package:flutter_python_bridge/src/python_bridge.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// A class that provides image processing capabilities using Python.
class ImageProcessor {
  /// The Python bridge instance
  final PythonBridge _pythonBridge;

  /// Creates a new [ImageProcessor] instance.
  ImageProcessor({PythonBridge? pythonBridge})
      : _pythonBridge = pythonBridge ?? PythonBridge();

  /// Processes an image using Python's OpenCV library.
  /// 
  /// [imagePath] is the path to the input image file.
  /// [operations] is a list of image processing operations to apply.
  /// [saveToAssets] determines whether to save the processed image to the assets folder (true) or temp directory (false).
  /// 
  /// Returns a [PythonResult] containing the path to the processed image.
  Future<PythonResult> processImage(String imagePath, List<ImageOperation> operations, {bool saveToAssets = false}) async {
    try {
      // Check if the input file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        return PythonResult.failure(error: 'Input image file not found: $imagePath');
      }

      final outputFileName = 'processed_${DateTime.now().millisecondsSinceEpoch}${path.extension(imagePath)}';
      
      // Generate Python code for image processing
      final pythonCode = _generateImageProcessingCode(
        inputPath: imagePath,
        outputFileName: outputFileName,
        operations: operations,
        saveToAssets: saveToAssets,
      );

      // Run the Python code
      final result = await _pythonBridge.runCode(pythonCode);

      if (result.success) {
        try {
          // Try to parse the JSON results to get the output path
          final jsonStart = result.output!.indexOf('{');
          final jsonEnd = result.output!.lastIndexOf('}') + 1;
          if (jsonStart >= 0 && jsonEnd > jsonStart) {
            final jsonStr = result.output!.substring(jsonStart, jsonEnd);
            final resultMap = json.decode(jsonStr);
            if (resultMap.containsKey('output_path')) {
              final outputPath = resultMap['output_path'];
              return PythonResult.success(
                output: result.output,
                returnValue: outputPath,
              );
            }
          }
        } catch (e) {
          print('Error parsing JSON results: $e');
        }
        
        return PythonResult.success(
          output: result.output,
          returnValue: null,
        );
      } else {
        return result;
      }
    } catch (e) {
      return PythonResult.failure(error: e.toString());
    }
  }

  /// Generates Python code for image processing based on the specified operations.
  /// This method is exposed for UI display purposes.
  String generateImageProcessingCode({
    required String inputPath,
    required String outputPath,
    required List<ImageOperation> operations,
  }) {
    return _generateImageProcessingCode(
      inputPath: inputPath,
      outputFileName: path.basename(outputPath),
      operations: operations,
      saveToAssets: false,
    );
  }

  /// Generates Python code for image processing based on the specified operations.
  String _generateImageProcessingCode({
    required String inputPath,
    required String outputFileName,
    required List<ImageOperation> operations,
    bool saveToAssets = false,
  }) {
    final operationsCode = operations.map((op) => op.toPythonCode()).join('\n');

    return '''import cv2
import numpy as np
import os
import json

# Define input path
input_path = '${inputPath.replaceAll('\\', '/')}'

# Create output directory
if ${saveToAssets ? 'True' : 'False'}:
    # Try to use app's assets directory (may not work on all platforms)
    try:
        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        output_dir = os.path.join(base_dir, 'example', 'assets', 'processed_images')
    except:
        # Fallback to home directory
        output_dir = os.path.join(os.path.expanduser('~'), 'processed_images')
else:
    # Use home directory
    output_dir = os.path.join(os.path.expanduser('~'), 'processed_images')

# Create directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

# Define output path
output_path = os.path.join(output_dir, '$outputFileName')

# Load the image
image = cv2.imread(input_path, cv2.IMREAD_UNCHANGED)

# Check if image was loaded successfully
if image is None:
    print(json.dumps({"error": f"Failed to load image from {input_path}"}))    
    exit(1)

# Get image dimensions
height, width = image.shape[:2]
print(f"Original image dimensions: {width}x{height}")

# Apply operations
$operationsCode

# Save the processed image
cv2.imwrite(output_path, image)
print(f"Image processed and saved to {output_path}")

# Return the output path
result = {"output_path": output_path}
print(json.dumps(result))
''';
  }

  /// Extracts text from an image using OCR (Optical Character Recognition).
  /// 
  /// [imagePath] is the path to the input image file.
  /// 
  /// Returns a [PythonResult] containing the extracted text.
  Future<PythonResult> extractTextFromImage(String imagePath) async {
    try {
      // Check if the input file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        return PythonResult.failure(error: 'Input image file not found: $imagePath');
      }

      // Generate Python code for OCR
      final pythonCode = '''
import cv2
import pytesseract
from PIL import Image

# Load the image
image_path = '${imagePath.replaceAll('\\', '/')}'
image = Image.open(image_path)

# Extract text using pytesseract
text = pytesseract.image_to_string(image)

# Print the extracted text
print(text)

# Return the extracted text
text
''';

      // Run the Python code
      return await _pythonBridge.runCode(pythonCode);
    } catch (e) {
      return PythonResult.failure(error: e.toString());
    }
  }

  /// Detects objects in an image using a pre-trained model.
  /// 
  /// [imagePath] is the path to the input image file.
  /// [confidenceThreshold] is the minimum confidence score for detections (0.0 to 1.0).
  /// 
  /// Returns a [PythonResult] containing a list of detected objects with their bounding boxes and confidence scores.
  Future<PythonResult> detectObjects(String imagePath, {double confidenceThreshold = 0.5}) async {
    try {
      // Check if the input file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        return PythonResult.failure(error: 'Input image file not found: $imagePath');
      }

      // Create a temporary directory for the output file
      final tempDir = await getTemporaryDirectory();
      final outputFileName = 'detected_${DateTime.now().millisecondsSinceEpoch}${path.extension(imagePath)}';
      final outputPath = path.join(tempDir.path, outputFileName);

      // Generate Python code for object detection
      final pythonCode = '''
import cv2
import numpy as np
import json

# Load the image
image_path = '${imagePath.replaceAll('\\', '/')}'
output_path = '${outputPath.replaceAll('\\', '/')}'
image = cv2.imread(image_path)
height, width, _ = image.shape

# Load YOLO model (using OpenCV's DNN module)
net = cv2.dnn.readNetFromDarknet(
    'yolov3.cfg',
    'yolov3.weights'
)

# Load class names
with open('coco.names', 'r') as f:
    classes = [line.strip() for line in f.readlines()]

# Get output layer names
layer_names = net.getLayerNames()
output_layers = [layer_names[i - 1] for i in net.getUnconnectedOutLayers()]

# Prepare the image for the network
blob = cv2.dnn.blobFromImage(image, 0.00392, (416, 416), (0, 0, 0), True, crop=False)
net.setInput(blob)
outs = net.forward(output_layers)

# Process detections
class_ids = []
confidences = []
boxes = []
for out in outs:
    for detection in out:
        scores = detection[5:]
        class_id = np.argmax(scores)
        confidence = scores[class_id]
        if confidence > ${confidenceThreshold}:
            # Object detected
            center_x = int(detection[0] * width)
            center_y = int(detection[1] * height)
            w = int(detection[2] * width)
            h = int(detection[3] * height)

            # Rectangle coordinates
            x = int(center_x - w / 2)
            y = int(center_y - h / 2)

            boxes.append([x, y, w, h])
            confidences.append(float(confidence))
            class_ids.append(class_id)

# Apply non-maximum suppression
indexes = cv2.dnn.NMSBoxes(boxes, confidences, ${confidenceThreshold}, 0.4)

# Prepare results
results = []
for i in range(len(boxes)):
    if i in indexes:
        x, y, w, h = boxes[i]
        label = str(classes[class_ids[i]])
        confidence = confidences[i]
        results.append({
            'label': label,
            'confidence': confidence,
            'box': [x, y, w, h]
        })
        
        # Draw bounding box on the image
        color = (0, 255, 0)  # Green
        cv2.rectangle(image, (x, y), (x + w, y + h), color, 2)
        cv2.putText(image, f'{label}: {confidence:.2f}', (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)

# Save the image with bounding boxes
cv2.imwrite(output_path, image)

# Print results as JSON
print(json.dumps(results))

# Return results
results
''';

      // Run the Python code
      final result = await _pythonBridge.runCode(pythonCode);

      if (result.success) {
        // Check if the output file was created
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          // Try to parse the JSON results
          try {
            final jsonStart = result.output?.indexOf('[') ?? -1;
            final jsonEnd = result.output?.lastIndexOf(']') ?? -1;
            if (jsonStart >= 0 && jsonEnd > jsonStart) {
              final jsonStr = result.output!.substring(jsonStart, jsonEnd + 1);
              final detections = json.decode(jsonStr);
              return PythonResult.success(
                output: result.output,
                returnValue: {
                  'detections': detections,
                  'annotatedImagePath': outputPath,
                },
              );
            }
          } catch (e) {
            // If JSON parsing fails, return the output file path anyway
            return PythonResult.success(
              output: result.output,
              returnValue: {
                'annotatedImagePath': outputPath,
              },
            );
          }
        }
      }
      
      return result;
    } catch (e) {
      return PythonResult.failure(error: e.toString());
    }
  }
}

/// Base class for image processing operations.
abstract class ImageOperation {
  /// Converts the operation to Python code.
  String toPythonCode();
}

/// Operation to resize an image.
class ResizeOperation extends ImageOperation {
  /// The target width
  final int width;
  
  /// The target height
  final int height;

  /// Creates a new [ResizeOperation].
  ResizeOperation({required this.width, required this.height});

  @override
  String toPythonCode() {
    return '''
# Resize the image
image = cv2.resize(image, ($width, $height))
''';
  }
}

/// Operation to convert an image to grayscale.
class GrayscaleOperation extends ImageOperation {
  @override
  String toPythonCode() {
    return '''
# Convert to grayscale
if len(image.shape) > 2 and image.shape[2] == 3:
    image = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    # Convert back to 3 channels for compatibility with other operations
    image = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
''';
  }
}

/// Operation to apply a blur effect to an image.
class BlurOperation extends ImageOperation {
  /// The kernel size for the blur
  final int kernelSize;

  /// Creates a new [BlurOperation].
  BlurOperation({this.kernelSize = 5});

  @override
  String toPythonCode() {
    return '''
# Apply Gaussian blur
image = cv2.GaussianBlur(image, ($kernelSize, $kernelSize), 0)
''';
  }
}

/// Operation to apply edge detection to an image.
class EdgeDetectionOperation extends ImageOperation {
  /// The threshold1 parameter for Canny edge detection
  final int threshold1;
  
  /// The threshold2 parameter for Canny edge detection
  final int threshold2;

  /// Creates a new [EdgeDetectionOperation].
  EdgeDetectionOperation({this.threshold1 = 100, this.threshold2 = 200});

  @override
  String toPythonCode() {
    return '''
# Apply Canny edge detection
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if len(image.shape) > 2 else image
edges = cv2.Canny(gray, $threshold1, $threshold2)
# Convert back to 3 channels for compatibility with other operations
image = cv2.cvtColor(edges, cv2.COLOR_GRAY2BGR)
''';
  }
}

/// Operation to adjust the brightness and contrast of an image.
class BrightnessContrastOperation extends ImageOperation {
  /// The brightness adjustment factor
  final double brightness;
  
  /// The contrast adjustment factor
  final double contrast;

  /// Creates a new [BrightnessContrastOperation].
  BrightnessContrastOperation({this.brightness = 0, this.contrast = 1});

  @override
  String toPythonCode() {
    return '''
# Adjust brightness and contrast
image = cv2.convertScaleAbs(image, alpha=$contrast, beta=$brightness)
''';
  }
}

/// Operation to rotate an image.
class RotateOperation extends ImageOperation {
  /// The rotation angle in degrees
  final double angle;

  /// Creates a new [RotateOperation].
  RotateOperation({required this.angle});

  @override
  String toPythonCode() {
    return '''
# Rotate the image
height, width = image.shape[:2]
center = (width / 2, height / 2)
rotation_matrix = cv2.getRotationMatrix2D(center, $angle, 1.0)
image = cv2.warpAffine(image, rotation_matrix, (width, height))
''';
  }
}

/// Operation to flip an image horizontally or vertically.
class FlipOperation extends ImageOperation {
  /// The flip code: 0 for vertical flip, 1 for horizontal flip, -1 for both
  final int flipCode;

  /// Creates a new [FlipOperation].
  /// 
  /// [flipCode] can be:
  /// - 0 for vertical flip (around x-axis)
  /// - 1 for horizontal flip (around y-axis)
  /// - -1 for both horizontal and vertical flip
  FlipOperation({required this.flipCode});

  @override
  String toPythonCode() {
    return '''
# Flip the image
image = cv2.flip(image, $flipCode)
''';
  }
}

/// Operation to crop an image.
class CropOperation extends ImageOperation {
  /// The x-coordinate of the top-left corner
  final int x;
  
  /// The y-coordinate of the top-left corner
  final int y;
  
  /// The width of the crop region
  final int width;
  
  /// The height of the crop region
  final int height;

  /// Creates a new [CropOperation].
  CropOperation({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  String toPythonCode() {
    return '''
# Crop the image
image = image[$y:$y+$height, $x:$x+$width]
''';
  }
}
