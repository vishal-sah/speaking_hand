class SignDetectionResult {
  final int classIndex;
  final String className;
  final double confidence;

  SignDetectionResult({
    required this.classIndex,
    required this.className,
    required this.confidence,
  });
}
