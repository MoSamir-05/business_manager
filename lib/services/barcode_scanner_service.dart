import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerService {
  BarcodeScannerService._();

  static final BarcodeScannerService instance =
      BarcodeScannerService._();

  // Only standard linear barcode formats.
  // QR codes and URLs will not be scanned.
  static const List<BarcodeFormat> supportedFormats = [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.codabar,
    BarcodeFormat.itf,
  ];

  final MobileScannerController controller =
      MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: supportedFormats,
    autoStart: false,
  );

  Stream<BarcodeCapture> get barcodeStream {
    return controller.barcodes;
  }

  Future<void> startScanner() async {
    await controller.start();
  }

  Future<void> stopScanner() async {
    await controller.stop();
  }

  Future<void> toggleTorch() async {
    await controller.toggleTorch();
  }

  Future<void> switchCamera() async {
    await controller.switchCamera();
  }

  // Extract only supported barcode numbers.
  String? extractBarcodeNumber(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      if (!supportedFormats.contains(barcode.format)) {
        continue;
      }

      final value = barcode.rawValue?.trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  Future<void> dispose() async {
    await controller.dispose();
  }
}