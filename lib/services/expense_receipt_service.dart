import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ExpenseReceiptService {
  ExpenseReceiptService._();

  static final ExpenseReceiptService instance =
      ExpenseReceiptService._();

  final ImagePicker _picker = ImagePicker();

  // Capture receipt using camera
  Future<String?> takeReceiptPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 1600,
    );

    if (image == null) {
      return null;
    }

    return await _saveReceipt(image);
  }

  // Select receipt from gallery
  Future<String?> selectReceiptFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );

    if (image == null) {
      return null;
    }

    return await _saveReceipt(image);
  }

  // Save receipt permanently in app documents
  Future<String> _saveReceipt(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();

    final receiptDirectory = Directory(
      p.join(
        directory.path,
        'business_manager_media',
        'receipts',
      ),
    );

    if (!await receiptDirectory.exists()) {
      await receiptDirectory.create(recursive: true);
    }

    final extension = p.extension(image.path).toLowerCase();

    final fileName =
        'receipt_${DateTime.now().microsecondsSinceEpoch}$extension';

    final destinationPath = p.join(
      receiptDirectory.path,
      fileName,
    );

    final savedFile = await File(image.path).copy(
      destinationPath,
    );

    return savedFile.path;
  }

  // Delete receipt
  Future<bool> deleteReceipt(String? receiptPath) async {
    if (receiptPath == null || receiptPath.isEmpty) {
      return false;
    }

    final file = File(receiptPath);

    if (!await file.exists()) {
      return false;
    }

    await file.delete();

    return true;
  }

  // Check whether receipt exists
  Future<bool> receiptExists(String? receiptPath) async {
    if (receiptPath == null || receiptPath.isEmpty) {
      return false;
    }

    return await File(receiptPath).exists();
  }

  // Get receipt file size
  Future<int> getReceiptSize(String receiptPath) async {
    final file = File(receiptPath);

    if (!await file.exists()) {
      return 0;
    }

    return await file.length();
  }
}