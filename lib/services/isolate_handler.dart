import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:speaking_hand/modal_class/sign_language_result.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class IsolateHandler {
  late Isolate _isolate;
  late SendPort _sendPort;
  final ReceivePort _receivePort = ReceivePort();
  bool _isInitialized = false;

  Future<void> init(Uint8List modelBytes, List<String> labels) async {
    final completer = Completer<SendPort>();
    _receivePort.listen((message) {
      if (message is SendPort && !_isInitialized) {
        _sendPort = message;
        _isInitialized = true;
        completer.complete(_sendPort);
      } else if (message is List<SignDetectionResult>) {
        _responseCompleter?.complete(message);
      }
    });

    _isolate = await Isolate.spawn(
      _isolateEntry,
      [_receivePort.sendPort, modelBytes, labels],
    );

    await completer.future;
  }

  Completer<List<SignDetectionResult>>? _responseCompleter;

  Future<List<SignDetectionResult>> predict(String imagePath) async {
    _responseCompleter = Completer<List<SignDetectionResult>>();
    _sendPort.send(imagePath);
    return _responseCompleter!.future;
  }

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    _receivePort.close();
  }

  static void _isolateEntry(List<dynamic> args) async {
    final SendPort mainSendPort = args[0];
    final Uint8List modelBytes = args[1];
    final List<String> labels = List<String>.from(args[2]);

    final interpreter = Interpreter.fromBuffer(modelBytes);
    final isolateReceivePort = ReceivePort();
    mainSendPort.send(isolateReceivePort.sendPort);

    isolateReceivePort.listen((dynamic message) async {
      if (message is String) {
        final result = await _runInference(interpreter, labels, message);
        mainSendPort.send(result);
      }
    });
  }

  static Future<List<SignDetectionResult>> _runInference(
    Interpreter interpreter,
    List<String> labels,
    String imagePath,
  ) async {
    try {
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return [];

      final resizedImage = img.copyResize(image, width: 224, height: 224);
      final inputData = [
        List.generate(
          224,
          (y) => List.generate(
            224,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return [
                pixel.r / 255.0,
                pixel.g / 255.0,
                pixel.b / 255.0,
              ];
            },
          ),
        ),
      ];

      final outputShape = interpreter.getOutputTensor(0).shape;
      final output = List<double>.filled(outputShape.reduce((a, b) => a * b), 0)
          .reshape(outputShape);

      interpreter.run(inputData, output);

      final flatConfidences =
          output.expand((batch) => batch).expand((row) => row).toList();

      final results = <SignDetectionResult>[];

      for (int i = 0; i < flatConfidences.length; i++) {
        results.add(SignDetectionResult(
          classIndex: i,
          className: labels[i % labels.length], // Adjust for label indexing
          confidence: flatConfidences[i],
        ));
      }

      return results;
      // return maxIdx < labels.length ? labels[maxIdx] : 'Out of Range';
    } catch (e) {
      debugPrint("Error in isolate prediction: $e");
      return [];
    }
  }
}
