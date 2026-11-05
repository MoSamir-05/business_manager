
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerService {
  BarcodeScannerService._();

  static final BarcodeScannerService instance =
      BarcodeScannerService._();

  final MobileScannerController controller =
      MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [
      BarcodeFormat.all,
    ],
    autoStart: false,
  );

  /// Barcode scanning stream.
  Stream<BarcodeCapture> get barcodeStream {
    return controller.barcodes;
  }

  /// Start camera scanning.
  Future<void> startScanner() async {
    await controller.start();
  }

  /// Stop camera scanning.
  Future<void> stopScanner() async {
    await controller.stop();
  }

  /// Turn flashlight on or off.
  Future<void> toggleTorch() async {
    await controller.toggleTorch();
  }

  /// Switch between front and back camera.
  Future<void> switchCamera() async {
    await controller.switchCamera();
  }

  /// Extract first valid barcode number.
  String? extractBarcodeNumber(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  /// Release camera resources.
  Future<void> dispose() async {
    await controller.dispose();
  }
}
