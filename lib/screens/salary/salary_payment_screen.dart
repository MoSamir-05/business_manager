
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/salary_model.dart';
import '../../models/salary_payment_model.dart';
import '../../services/salary_payment_service.dart';

class SalaryPaymentScreen extends StatefulWidget {
  final SalaryModel salary;

  const SalaryPaymentScreen({
    super.key,
    required this.salary,
  });

  @override
  State<SalaryPaymentScreen> createState() =>
      _SalaryPaymentScreenState();
}

class _SalaryPaymentScreenState extends State<SalaryPaymentScreen> {
  final SalaryPaymentService _paymentService =
      SalaryPaymentService.instance;

  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _noteController =
      TextEditingController();

  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayDateFormat = DateFormat('dd MMM yyyy');

  List<SalaryPaymentModel> _payments = [];

  String _paymentMethod = SalaryPaymentModel.cash;
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = true;
  bool _isSaving = false;

  double get _remainingAmount => widget.salary.remainingAmount;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    if (widget.salary.id == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await _paymentService.getPaymentsBySalaryId(
        widget.salary.id!,
      );

      if (!mounted) return;

      setState(() {
        _payments = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment history load nahi hui: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _savePayment() async {
    if (widget.salary.id == null) {
      _showMessage('Salary record ID nahi mila.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      _showMessage('Valid payment amount enter karo.');
      return;
    }

    if (amount > _remainingAmount) {
      _showMessage('Payment pending amount se zyada nahi ho sakti.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _paymentService.addPayment(
        salaryRecordId: widget.salary.id!,
        amount: amount,
        paymentDate: _dateFormat.format(_selectedDate),
        paymentMethod: _paymentMethod,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) return;

      _amountController.clear();
      _noteController.clear();

      await _loadPayments();

      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salary payment successfully save ho gayi.'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);
      _showMessage('Payment save nahi hui: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Salary Payment Summary',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          _summaryRow(
            'Total Salary',
            _formatCurrency(widget.salary.finalPayable),
          ),
          const SizedBox(height: 10),
          _summaryRow(
            'Already Paid',
            _formatCurrency(widget.salary.paidAmount),
          ),
          const Divider(color: Colors.white30, height: 25),
          _summaryRow(
            'Pending Amount',
            _formatCurrency(_remainingAmount),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String title,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isBold ? 19 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(15),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            _buildTextField(
              label: 'Payment Amount (₹)',
              controller: _amountController,
              hint: 'Enter amount',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Payment Date',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month),
                    const SizedBox(width: 12),
                    Text(_displayDateFormat.format(_selectedDate)),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: InputDecoration(
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: SalaryPaymentModel.cash,
                  child: Text('Cash'),
                ),
                DropdownMenuItem(
                  value: SalaryPaymentModel.upi,
                  child: Text('UPI'),
                ),
                DropdownMenuItem(
                  value: SalaryPaymentModel.bank,
                  child: Text('Bank'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _paymentMethod = value);
                }
              },
            ),

            const SizedBox(height: 18),

            _buildTextField(
              label: 'Note (Optional)',
              controller: _noteController,
              hint: 'Enter payment note',
              maxLines: 3,
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving || _remainingAmount <= 0
                    ? null
                    : _savePayment,
                icon: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Payment',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistory() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_payments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 25),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 42, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                'No payment history available',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _payments.map((payment) {
        DateTime? date;

        try {
          date = DateTime.parse(payment.paymentDate);
        } catch (_) {
          date = null;
        }

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: AppTheme.border),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.success.withOpacity(0.12),
              child: const Icon(
                Icons.payments_outlined,
                color: AppTheme.success,
              ),
            ),
            title: Text(
              _formatCurrency(payment.amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${payment.paymentMethod} • '
              '${date == null ? payment.paymentDate : _displayDateFormat.format(date)}'
              '${payment.note == null || payment.note!.isEmpty ? '' : '\n${payment.note}'}',
            ),
            isThreeLine: payment.note != null &&
                payment.note!.isNotEmpty,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Payments'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAmountCard(),
              const SizedBox(height: 22),

              if (_remainingAmount > 0) ...[
                _buildPaymentForm(),
                const SizedBox(height: 25),
              ] else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Salary fully paid ho chuki hai.',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentHistory(),
            ],
          ),
        ),
      ),
    );
  }
}
