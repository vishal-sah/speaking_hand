import 'package:flutter/material.dart';
import 'package:speaking_hand/widgets/camera_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isCameraInitialized = false;
  String detectedText = "";
  final ValueNotifier<int> toggleCameraNotifier = ValueNotifier(0);

  final TextStyle subtitleStyle = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(blurRadius: 3.0, color: Colors.black, offset: Offset(1.0, 1.0)),
    ],
  );
  void startCamera() {
    setState(() {
      isCameraInitialized = true;
    });
  }

  void onSignDetected(String text) {
    setState(() {
      detectedText = text;
    });
  }

  void toggleCamera() {
    toggleCameraNotifier.value = toggleCameraNotifier.value == 0 ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speaking Hand')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Camera or start camera button
                isCameraInitialized
                    ? CameraView(
                      onSignDetected: onSignDetected,
                      toggleCameraNotifier: toggleCameraNotifier,
                    )
                    : Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Start Camera'),
                        onPressed: startCamera,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                if (isCameraInitialized)
                  Positioned(
                    right: 20,
                    top: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.cameraswitch, color: Colors.white),
                        onPressed: toggleCamera,
                        tooltip: 'Toggle Camera',
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info text at bottom
          Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: const Text(
              'Make signs to translate to text',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
