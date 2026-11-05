
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/app_theme.dart';
import '../../services/barcode_scanner_service.dart';
import '../../services/barcode_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  final BarcodeScannerService _scannerService =
      BarcodeScannerService.instance;

  final BarcodeService _barcodeService = BarcodeService.instance;

  final TextEditingController _manualController =
      TextEditingController();

  bool _isSaving = false;
  bool _isCameraStarted = false;
  bool _isTorchOn = false;
  bool _isProcessing = false;

  String? _lastScannedBarcode;
  String _message = 'Barcode ko camera ke saamne rakhein.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualController.dispose();
    _scannerService.stopScanner();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _scannerService.stopScanner();
      _isCameraStarted = false;
    }
  }

  Future<void> _startCamera() async {
    try {
      await _scannerService.startScanner();

      if (!mounted) return;

      setState(() {
        _isCameraStarted = true;
        _message = 'Barcode ko camera ke saamne rakhein.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCameraStarted = false;
        _message = 'Camera start nahi hua. Permission check karein.';
      });
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _scannerService.stopScanner();

      if (!mounted) return;

      setState(() {
        _isCameraStarted = false;
      });
    } catch (_) {}
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerService.toggleTorch();

      if (!mounted) return;

      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (e) {
      _showMessage('Flashlight available nahi hai.');
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerService.switchCamera();
    } catch (e) {
      _showMessage('Camera switch nahi ho saka.');
    }
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing || _isSaving) return;

    final barcodeNumber =
        _scannerService.extractBarcodeNumber(capture);

    if (barcodeNumber == null || barcodeNumber.isEmpty) return;

    if (barcodeNumber == _lastScannedBarcode) return;

    _isProcessing = true;
    _lastScannedBarcode = barcodeNumber;

    await _saveBarcode(barcodeNumber);

    _isProcessing = false;
  }

  Future<void> _saveBarcode(String barcodeNumber) async {
    if (!mounted) return;

    setState(() {
      _isSaving = true;
      _message = 'Barcode save ho raha hai...';
    });

    try {
      await _barcodeService.addBarcode(barcodeNumber);

      if (!mounted) return;

      setState(() {
        _message = 'Barcode successfully save ho gaya!';
      });

      _showMessage(
        'Barcode saved: $barcodeNumber',
        color: AppTheme.success,
      );
    } on StateError {
      if (!mounted) return;

      setState(() {
        _message = 'Ye barcode pehle se saved hai.';
      });

      _showMessage(
        'Ye barcode already saved hai.',
        color: AppTheme.warning,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Barcode save nahi hua.';
      });

      _showMessage('Error: $e', color: AppTheme.danger);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveManualBarcode() async {
    final barcodeNumber = _manualController.text.trim();

    if (barcodeNumber.isEmpty) {
      _showMessage('Barcode number enter karein.');
      return;
    }

    if (_isSaving) return;

    await _saveBarcode(barcodeNumber);

    if (mounted) {
      _manualController.clear();
    }
  }

  void _showMessage(
    String message, {
    Color? color,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _buildScannerView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerService.controller,
            onDetect: _onBarcodeDetected,
          ),

          IgnorePointer(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

          Positioned(
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Barcode ko frame ke andar rakhein',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          if (_isSaving)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          onPressed: _toggleTorch,
          icon: Icon(
            _isTorchOn ? Icons.flash_on : Icons.flash_off,
          ),
          tooltip: 'Flashlight',
        ),
        const SizedBox(width: 25),
        IconButton.filledTonal(
          onPressed: _switchCamera,
          icon: const Icon(Icons.flip_camera_android),
          tooltip: 'Switch camera',
        ),
        const SizedBox(width: 25),
        IconButton.filledTonal(
          onPressed: _isCameraStarted
              ? _stopCamera
              : _startCamera,
          icon: Icon(
            _isCameraStarted ? Icons.pause : Icons.play_arrow,
          ),
          tooltip: _isCameraStarted ? 'Stop camera' : 'Start camera',
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _message,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntry() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual Barcode Entry',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _manualController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Enter barcode number',
                prefixIcon: const Icon(Icons.qr_code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onSubmitted: (_) => _saveManualBarcode(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveManualBarcode,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Barcode'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/barcode-history');
            },
            icon: const Icon(Icons.history),
            tooltip: 'Barcode History',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scan Barcode',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Camera se barcode scan karke automatically save karein.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              AspectRatio(
                aspectRatio: 1.15,
                child: _buildScannerView(),
              ),

              const SizedBox(height: 17),
              _buildCameraControls(),
              const SizedBox(height: 20),
              _buildStatusCard(),
              const SizedBox(height: 25),
              _buildManualEntry(),
            ],
          ),
        ),
      ),
    );
  }
}
