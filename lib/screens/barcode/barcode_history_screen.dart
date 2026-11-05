
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/barcode_model.dart';
import '../../services/barcode_service.dart';

class BarcodeHistoryScreen extends StatefulWidget {
  const BarcodeHistoryScreen({super.key});

  @override
  State<BarcodeHistoryScreen> createState() =>
      _BarcodeHistoryScreenState();
}

class _BarcodeHistoryScreenState extends State<BarcodeHistoryScreen> {
  final BarcodeService _barcodeService = BarcodeService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<BarcodeModel> _barcodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBarcodes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBarcodes() async {
    setState(() => _isLoading = true);

    try {
      final result = await _barcodeService.getAllBarcodes();

      if (!mounted) return;

      setState(() {
        _barcodes = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('Barcode history load nahi hui: $e');
    }
  }

  Future<void> _searchBarcodes(String query) async {
    try {
      final result = query.trim().isEmpty
          ? await _barcodeService.getAllBarcodes()
          : await _barcodeService.searchBarcodes(query);

      if (!mounted) return;

      setState(() {
        _barcodes = result;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Search nahi ho saka: $e');
    }
  }

  // Edit barcode
  Future<void> _editBarcode(BarcodeModel barcode) async {
    if (barcode.id == null) return;

    final controller = TextEditingController(
      text: barcode.barcodeNumber,
    );

    final formKey = GlobalKey<FormState>();

    final updatedNumber = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Barcode'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Barcode Number',
                prefixIcon: Icon(Icons.qr_code_2),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Barcode number required';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(
                    dialogContext,
                    controller.text.trim(),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (updatedNumber == null || !mounted) return;

    try {
      await _barcodeService.updateBarcode(
        barcode.id!,
        updatedNumber,
      );

      if (!mounted) return;

      await _searchBarcodes(_searchController.text);

      _showMessage(
        'Barcode update ho gaya.',
        color: AppTheme.success,
      );
    } on StateError catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Barcode update nahi hua: $e');
    }
  }

  // Delete barcode
  Future<void> _deleteBarcode(BarcodeModel barcode) async {
    if (barcode.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Barcode?'),
          content: Text(
            'Kya aap barcode "${barcode.barcodeNumber}" delete karna chahte hain?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.danger,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _barcodeService.deleteBarcode(barcode.id!);

      if (!mounted) return;

      await _searchBarcodes(_searchController.text);

      _showMessage(
        'Barcode delete ho gaya.',
        color: AppTheme.success,
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Barcode delete nahi hua: $e');
    }
  }

  void _showMessage(String message, {Color? color}) {
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

  // Show date and exact scan time
  String _formatDate(String value) {
    try {
      final date = DateTime.parse(value).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return value;
    }
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _searchBarcodes,
      decoration: InputDecoration(
        hintText: 'Search barcode number...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: () {
            _searchController.clear();
            _searchBarcodes('');
          },
          icon: const Icon(Icons.close),
        ),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              color: AppTheme.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saved Barcodes',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_barcodes.length}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeCard(BarcodeModel barcode) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.qr_code_2,
                color: AppTheme.primary,
                size: 27,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    barcode.barcodeNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(barcode.scannedAt),
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _editBarcode(barcode),
              icon: const Icon(
                Icons.edit_outlined,
                color: AppTheme.primary,
              ),
              tooltip: 'Edit barcode',
            ),
            IconButton(
              onPressed: () => _deleteBarcode(barcode),
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.danger,
              ),
              tooltip: 'Delete barcode',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 55,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 15),
            const Text(
              'No barcode found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try another barcode number.'
                  : 'Scan your first barcode to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
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
        title: const Text('Barcode History'),
        actions: [
          IconButton(
            onPressed: _loadBarcodes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadBarcodes,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummary(),
                    const SizedBox(height: 20),
                    _buildSearchBar(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Saved Barcode List',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${_barcodes.length} records',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_barcodes.isEmpty)
                      _buildEmptyState()
                    else
                      ..._barcodes.map(_buildBarcodeCard),
                  ],
                ),
              ),
      ),
    );
  }
}
