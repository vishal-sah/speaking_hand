import 'dart:async';
import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class IsolateHandler {
  late Isolate _isolate;
  late SendPort _sendPort;
  final ReceivePort _receivePort = ReceivePort();
  bool _isInitialized = false;

  Future<void> init(
    Uint8List handDetectorBytes,
    Uint8List handLandmarkBytes,
    Uint8List signModelBytes, // not used yet
    List<String> labels,
  ) async {
    final completer = Completer<SendPort>();
    _receivePort.listen((message) {
      if (message is SendPort && !_isInitialized) {
        _sendPort = message;
        _isInitialized = true;
        completer.complete(_sendPort);
      } else if (message is List<dynamic>) {
        _responseCompleter?.complete(message);
      }
    });

    _isolate = await Isolate.spawn(
      _isolateEntry,
      [
        _receivePort.sendPort,
        handDetectorBytes,
        handLandmarkBytes,
        signModelBytes,
        labels,
      ],
    );

    await completer.future;
  }

  Completer<List<dynamic>>? _responseCompleter;

  Future<List<dynamic>> predict(String imagePath) async {
    _responseCompleter = Completer<List<dynamic>>();
    _sendPort.send(imagePath);
    return _responseCompleter!.future;
  }

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    _receivePort.close();
  }

  static void _isolateEntry(List<dynamic> args) async {
    final SendPort mainSendPort = args[0];
    final Uint8List handDetectorBytes = args[1];
    final Uint8List handLandmarkBytes = args[2];
    final Uint8List signModelBytes = args[3];
    final List<String> labels = List<String>.from(args[4]);

    final handDetector = Interpreter.fromBuffer(handDetectorBytes);
    final handLandmark = Interpreter.fromBuffer(handLandmarkBytes);
    // final signModel = Interpreter.fromBuffer(signModelBytes); // Placeholder

    final isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);

    isolateReceivePort.listen((dynamic message) async {
      if (message is String) {
        final result = await _runInference(
          message,
          handDetector,
          handLandmark,
          labels,
        );
        mainSendPort.send(result);
      }
    });
  }

  static Future<List<dynamic>> _runInference(
    String imagePath,
    Interpreter detector,
    Interpreter landmark,
    List<String> labels,
  ) async {
    try {
      print(1);
      final imageBytes = await File(imagePath).readAsBytes();
      print(1);
      final decodedImage = img.decodeImage(imageBytes);
      print(1);
      if (decodedImage == null) return [];

      // Resize for hand detector
      final inputImage = img.copyResize(decodedImage, width: 224, height: 224);
      print(1);
      // Prepare detector input
      final input = List.generate(
        1,
        (_) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) {
              final pixel = inputImage.getPixel(x, y);
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      );
      print(1);

      List<int> outputShape = detector.getOutputTensor(0).shape;
      final detectorOutput = List<double>.filled(
        outputShape.reduce((a, b) => a * b),
        0.0,
      ).reshape(outputShape);
      print(1);
      detector.run(input, detectorOutput);

      print(detectorOutput[0][0].length);

      print("Detector Output: $detectorOutput");

      // Use detector output to crop region of interest (mocked for now)
      final roi = img.copyCrop(inputImage,
          x: 50,
          y: 50,
          width: 150,
          height: 150); // TODO: Replace with real bbox
      final resizedROI = img.copyResize(roi, width: 224, height: 224);

      final landmarkInput = List.generate(
        1,
        (_) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) {
              final pixel = resizedROI.getPixel(x, y);
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      );

      outputShape = landmark.getOutputTensor(0).shape;
      final landmarkOutput =
          List<double>.filled(outputShape.reduce((a, b) => a * b), 0)
              .reshape(outputShape);

      landmark.run(landmarkInput, landmarkOutput);

      print("Landmark Output Shape: $outputShape");

      debugPrint("Landmark Output: $landmarkOutput");

      return [landmarkOutput];
    } catch (e) {
      debugPrint("Error in prediction pipeline: $e");
      return [];
    }
  }
}
