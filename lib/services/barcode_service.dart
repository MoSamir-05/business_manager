
import '../database/database_helper.dart';
import '../models/barcode_model.dart';

class BarcodeService {
  BarcodeService._();

  static final BarcodeService instance = BarcodeService._();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Save a new barcode
  Future<int> addBarcode(String barcodeNumber) async {
    final number = barcodeNumber.trim();

    if (number.isEmpty) {
      throw ArgumentError('Barcode number cannot be empty.');
    }

    final db = await _databaseHelper.database;

    final existing = await db.query(
      'barcodes',
      columns: ['id'],
      where: 'barcode_number = ?',
      whereArgs: [number],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw StateError('This barcode is already saved.');
    }

    final barcode = BarcodeModel(
      barcodeNumber: number,
      scannedAt: DateTime.now().toIso8601String(),
    );

    return await db.insert('barcodes', barcode.toMap());
  }

  // Update existing barcode
  Future<int> updateBarcode(int id, String barcodeNumber) async {
    final number = barcodeNumber.trim();

    if (number.isEmpty) {
      throw ArgumentError('Barcode number cannot be empty.');
    }

    final db = await _databaseHelper.database;

    // Check duplicate, excluding current barcode
    final existing = await db.query(
      'barcodes',
      columns: ['id'],
      where: 'barcode_number = ? AND id != ?',
      whereArgs: [number, id],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw StateError('This barcode is already saved.');
    }

    return await db.update(
      'barcodes',
      {'barcode_number': number},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get all barcode history
  Future<List<BarcodeModel>> getAllBarcodes() async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'barcodes',
      orderBy: 'scanned_at DESC, id DESC',
    );

    return result.map((map) => BarcodeModel.fromMap(map)).toList();
  }

  // Search barcode by number
  Future<List<BarcodeModel>> searchBarcodes(String query) async {
    final db = await _databaseHelper.database;

    final searchQuery = '%${query.trim()}%';

    final result = await db.query(
      'barcodes',
      where: 'barcode_number LIKE ?',
      whereArgs: [searchQuery],
      orderBy: 'scanned_at DESC',
    );

    return result.map((map) => BarcodeModel.fromMap(map)).toList();
  }

  // Check whether barcode already exists
  Future<bool> barcodeExists(String barcodeNumber) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'barcodes',
      columns: ['id'],
      where: 'barcode_number = ?',
      whereArgs: [barcodeNumber.trim()],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // Get barcode by ID
  Future<BarcodeModel?> getBarcodeById(int id) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'barcodes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return BarcodeModel.fromMap(result.first);
  }

  // Delete barcode
  Future<int> deleteBarcode(int id) async {
    final db = await _databaseHelper.database;

    return await db.delete(
      'barcodes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total saved barcode count
  Future<int> getBarcodeCount() async {
    final db = await _databaseHelper.database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) AS total
      FROM barcodes
    ''');

    return (result.first['total'] as int?) ?? 0;
  }
}
