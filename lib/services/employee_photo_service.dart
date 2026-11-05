import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class EmployeePhotoService {
  EmployeePhotoService._();

  static final EmployeePhotoService instance =
      EmployeePhotoService._();

  final ImagePicker _picker = ImagePicker();

  // Pick photo from camera
  Future<String?> takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (image == null) {
      return null;
    }

    return await _savePhoto(image);
  }

  // Pick photo from gallery
  Future<String?> selectFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (image == null) {
      return null;
    }

    return await _savePhoto(image);
  }

  // Save photo permanently in app documents
  Future<String> _savePhoto(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();

    final photoDirectory = Directory(
      p.join(directory.path, 'business_manager_media', 'employees'),
    );

    if (!await photoDirectory.exists()) {
      await photoDirectory.create(recursive: true);
    }

    final extension = p.extension(image.path).toLowerCase();

    final fileName =
        'employee_${DateTime.now().microsecondsSinceEpoch}$extension';

    final destinationPath = p.join(
      photoDirectory.path,
      fileName,
    );

    final savedFile = await File(image.path).copy(destinationPath);

    return savedFile.path;
  }

  // Delete employee photo
  Future<bool> deletePhoto(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) {
      return false;
    }

    final file = File(photoPath);

    if (!await file.exists()) {
      return false;
    }

    await file.delete();

    return true;
  }

  // Check whether employee photo exists
  Future<bool> photoExists(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) {
      return false;
    }

    return await File(photoPath).exists();
  }
}