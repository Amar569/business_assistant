import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_state.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_bloc.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_state.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:business_assistant/core/services/business_info_service.dart';
import 'package:business_assistant/presentation/screens/widgets/custom_text_field.dart';
import 'package:business_assistant/presentation/screens/widgets/custom_button.dart';

class QrPaymentScreen extends StatefulWidget {
  final InvoiceEntity? invoice; // optional preselected invoice

  const QrPaymentScreen({super.key, this.invoice});

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  CustomerEntity? _selectedCustomer;
  InvoiceEntity? _selectedInvoice;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String? _upiId;
  String? _businessName;
  bool _isLoading = true;
  String? _qrData;

  @override
  void initState() {
    super.initState();
    _loadBusinessInfo();

    if (widget.invoice != null) {
      _selectedInvoice = widget.invoice;
      _amountController.text = widget.invoice!.total.toStringAsFixed(2);
      _noteController.text = 'Invoice ${widget.invoice!.invoiceNumber}';
    }
  }

  Future<void> _loadBusinessInfo() async {
    final info = await BusinessInfoService.load();
    setState(() {
      _upiId = (info['upiId'] as String?)?.trim();
      _businessName = (info['name'] as String?)?.trim();
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _buildUpiUri() {
    final payeeName = Uri.encodeComponent(
        (_businessName?.isNotEmpty ?? false) ? _businessName! : 'Business');
    final amount = _amountController.text.trim();
    final note = Uri.encodeComponent(_noteController.text.trim().isEmpty
        ? 'Payment'
        : _noteController.text.trim());

    // Standard UPI deep link format
    final buffer = StringBuffer('upi://pay?pa=$_upiId&pn=$payeeName');
    if (amount.isNotEmpty) {
      buffer.write('&am=$amount');
    }
    buffer.write('&tn=$note&cu=INR');
    return buffer.toString();
  }

  void _generateQr() {
    if (_upiId == null || _upiId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No UPI ID set. Please add one in Settings → Payment Settings.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (_amountController.text.trim().isNotEmpty &&
        (amount == null || amount <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a valid amount or leave it blank'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _qrData = _buildUpiUri();
    });
  }

  Future<void> _openInUpiApp() async {
    if (_qrData == null) return;
    final uri = Uri.parse(_qrData!);

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No UPI app found on this device. Please install Google Pay, PhonePe, or similar to use this feature.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open UPI app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Payment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_upiId == null || _upiId!.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'No UPI ID configured. Add one in Settings to generate QR codes.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Customer Selection (optional — for record-keeping/context)
                  BlocBuilder<CustomerBloc, CustomerState>(
                    builder: (context, state) {
                      if (state is CustomerLoaded) {
                        return DropdownButtonFormField<CustomerEntity>(
                          decoration: const InputDecoration(
                            labelText: 'Customer (optional)',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCustomer,
                          items: state.customers.map((customer) {
                            return DropdownMenuItem(
                              value: customer,
                              child: Text(customer.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCustomer = value;
                              _selectedInvoice = null;
                              _qrData = null;
                            });
                          },
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                  const SizedBox(height: 16),

                  // Invoice selection (optional — auto-fills amount)
                  if (_selectedCustomer != null)
                    BlocBuilder<InvoiceBloc, InvoiceState>(
                      builder: (context, state) {
                        if (state is InvoiceLoaded) {
                          final customerInvoices = state.invoices
                              .where((inv) =>
                                  inv.customerId == _selectedCustomer!.id &&
                                  inv.status != 'Paid' &&
                                  inv.status != 'Cancelled')
                              .toList();

                          if (customerInvoices.isEmpty) {
                            return const SizedBox();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: DropdownButtonFormField<InvoiceEntity>(
                              decoration: const InputDecoration(
                                labelText: 'Invoice (optional)',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedInvoice,
                              items: customerInvoices.map((invoice) {
                                return DropdownMenuItem(
                                  value: invoice,
                                  child: Text(
                                    '${invoice.invoiceNumber} — Rs${invoice.total.toStringAsFixed(2)}',
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedInvoice = value;
                                  if (value != null) {
                                    _amountController.text =
                                        value.total.toStringAsFixed(2);
                                    _noteController.text =
                                        'Invoice ${value.invoiceNumber}';
                                  }
                                  _qrData = null;
                                });
                              },
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),

                  CustomTextField(
                    label: 'Amount (leave blank for any amount)',
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.currency_rupee,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Note',
                    controller: _noteController,
                    prefixIcon: Icons.note,
                  ),
                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Generate QR Code',
                    onPressed: _generateQr,
                  ),
                  const SizedBox(height: 24),

                  if (_qrData != null) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _qrData!,
                          version: QrVersions.auto,
                          size: 240,
                          gapless: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _amountController.text.trim().isEmpty
                            ? 'Scan to pay via any UPI app'
                            : 'Rs${_amountController.text.trim()} • Scan to pay',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Open in UPI App',
                      isOutlined: true,
                      onPressed: _openInUpiApp,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
