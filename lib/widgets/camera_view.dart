import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:speaking_hand/services/isolate_handler.dart';

class CameraView extends StatefulWidget {
  final Function(String) onSignDetected;
  final ValueNotifier<void> toggleCameraNotifier;

  const CameraView({
    Key? key,
    required this.onSignDetected,
    required this.toggleCameraNotifier,
  }) : super(key: key);

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isDetecting = false;
  Timer? _captureTimer;
  // final SignLanguageService _signLanguageService = SignLanguageService();
  late final List<String> globalLabels;
  late final Uint8List globalModel;
  late final IsolateHandler _isolateHandler;

  Future<void> initIsolateAndStartCamera() async {
    final modelBytes = await rootBundle.load('assets/model2.tflite');
    final labelsFile = await rootBundle.loadString('assets/labels2.txt');
    final labels = labelsFile.split('\n');

    _isolateHandler = IsolateHandler();
    await _isolateHandler.init(modelBytes.buffer.asUint8List(), labels);

    _initializeCamera();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initIsolateAndStartCamera();
    widget.toggleCameraNotifier.addListener(() {
      _toggleCamera();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _captureTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras.isEmpty) {
        return;
      }

      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {});

        _startCapturingFrames();
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _toggleCamera() async {
    if (_cameras.isEmpty || _cameraController == null) {
      return;
    }

    final currentCamera = _cameraController!.description;
    final newCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection != currentCamera.lensDirection,
      orElse: () => currentCamera,
    );

    await _cameraController!.dispose();

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error toggling camera: $e');
    }
  }

  void _startCapturingFrames() {
    _captureTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _processFrame(),
    );
  }

  Future<void> _processFrame() async {
    if (_isDetecting ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    _isDetecting = true;

    try {
      // Capture a frame from the camera
      final XFile image = await _cameraController!.takePicture();

      // Process the captured image with the sign language model

      // final result = await _signLanguageService.detectSign(image.path);

      // final result = await _signLanguageService.detectSign(image.path);

      final results = await _isolateHandler.predict(image.path);

      // final result =
      // await detectSignInIsolate(image.path, globalModel, globalLabels);

      // If a sign is detected, call the callback
      if (results.isNotEmpty) {
        final best =
            results.reduce((a, b) => a.confidence > b.confidence ? a : b);
        widget.onSignDetected(best.className);
        print(best.className);
      } else {
        widget.onSignDetected('');
      }
    } catch (e) {
      print('Error processing frame: $e');
    } finally {
      if (mounted) {
        _isDetecting = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: 1 / _cameraController!.value.aspectRatio,
      child: CameraPreview(_cameraController!),
    );
  }
}
