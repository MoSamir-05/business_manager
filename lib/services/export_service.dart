import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  ExportService._();

  static final ExportService instance = ExportService._();

  // Export report as PDF
  Future<String> exportToPdf({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    String? fileName,
  }) async {
    if (headers.isEmpty) {
      throw ArgumentError('Report headers cannot be empty.');
    }

    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            pw.Text(
              'Business Manager',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Generated: ${DateTime.now().toString().substring(0, 16)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              cellPadding: const pw.EdgeInsets.all(7),
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              'Total Records: ${rows.length}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ];
        },
      ),
    );

    final directory = await _getExportDirectory();

    final safeName = _safeFileName(
      fileName ?? title,
    );

    final path = p.join(
      directory.path,
      '${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );

    final file = File(path);

    await file.writeAsBytes(
      await document.save(),
      flush: true,
    );

    return file.path;
  }

  // Export report as Excel
  Future<String> exportToExcel({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    String? fileName,
  }) async {
    if (headers.isEmpty) {
      throw ArgumentError('Report headers cannot be empty.');
    }

    final excel = Excel.createExcel();

    final sheet = excel['Report'];

    // Report title
    sheet.appendRow([
      TextCellValue('Business Manager'),
    ]);

    sheet.appendRow([
      TextCellValue(title),
    ]);

    sheet.appendRow([
      TextCellValue(
        'Generated: ${DateTime.now().toString().substring(0, 16)}',
      ),
    ]);

    sheet.appendRow([]);

    // Column headings
    sheet.appendRow(
      headers.map((header) => TextCellValue(header)).toList(),
    );

    // Report data
    for (final row in rows) {
      sheet.appendRow(
        row.map((value) => TextCellValue(value)).toList(),
      );
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    final bytes = excel.save();

    if (bytes == null) {
      throw Exception('Could not generate Excel file.');
    }

    final directory = await _getExportDirectory();

    final safeName = _safeFileName(
      fileName ?? title,
    );

    final path = p.join(
      directory.path,
      '${safeName}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );

    final file = File(path);

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    return file.path;
  }

  // Get export directory
  Future<Directory> _getExportDirectory() async {
    final appDirectory =
        await getApplicationDocumentsDirectory();

    final exportDirectory = Directory(
      p.join(appDirectory.path, 'BusinessManagerExports'),
    );

    if (!await exportDirectory.exists()) {
      await exportDirectory.create(recursive: true);
    }

    return exportDirectory;
  }

  // Make filename safe
  String _safeFileName(String name) {
    final cleaned = name
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    return cleaned.isEmpty ? 'Business_Report' : cleaned;
  }
}