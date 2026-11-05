class BarcodeModel {
  final int? id;
  final String barcodeNumber;
  final String scannedAt;

  const BarcodeModel({
    this.id,
    required this.barcodeNumber,
    required this.scannedAt,
  });

  // Database Map se Barcode Object
  factory BarcodeModel.fromMap(Map<String, dynamic> map) {
    return BarcodeModel(
      id: map['id'] as int?,
      barcodeNumber: map['barcode_number'] as String,
      scannedAt: map['scanned_at'] as String,
    );
  }

  // Barcode Object se Database Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'barcode_number': barcodeNumber,
      'scanned_at': scannedAt,
    };
  }

  // Existing Barcode Update
  BarcodeModel copyWith({
    int? id,
    String? barcodeNumber,
    String? scannedAt,
  }) {
    return BarcodeModel(
      id: id ?? this.id,
      barcodeNumber: barcodeNumber ?? this.barcodeNumber,
      scannedAt: scannedAt ?? this.scannedAt,
    );
  }
}