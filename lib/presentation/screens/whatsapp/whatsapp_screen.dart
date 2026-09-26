import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_state.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_bloc.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_state.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:business_assistant/core/services/business_info_service.dart';
import 'package:business_assistant/presentation/screens/widgets/custom_button.dart';

enum _MessageTemplate { invoiceReminder, paymentThanks, custom }

class WhatsAppScreen extends StatefulWidget {
  final CustomerEntity? customer; // optional preselected customer
  final InvoiceEntity? invoice; // optional preselected invoice

  const WhatsAppScreen({super.key, this.customer, this.invoice});

  @override
  State<WhatsAppScreen> createState() => _WhatsAppScreenState();
}

class _WhatsAppScreenState extends State<WhatsAppScreen> {
  CustomerEntity? _selectedCustomer;
  InvoiceEntity? _selectedInvoice;
  _MessageTemplate _template = _MessageTemplate.invoiceReminder;
  final TextEditingController _messageController = TextEditingController();
  String _businessName = '';

  @override
  void initState() {
    super.initState();
    _selectedCustomer = widget.customer;
    _selectedInvoice = widget.invoice;
    _loadBusinessInfo();
    _rebuildMessage();
  }

  Future<void> _loadBusinessInfo() async {
    final info = await BusinessInfoService.load();
    setState(() {
      _businessName = (info['name'] as String?)?.trim() ?? '';
    });
    _rebuildMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _rebuildMessage() {
    if (_template == _MessageTemplate.custom) return;

    final customerName = _selectedCustomer?.name ?? 'there';
    final biz = _businessName.isNotEmpty ? _businessName : 'us';

    switch (_template) {
      case _MessageTemplate.invoiceReminder:
        if (_selectedInvoice != null) {
          _messageController.text =
              'Hi $customerName, this is a reminder that invoice '
              '${_selectedInvoice!.invoiceNumber} for Rs${_selectedInvoice!.total.toStringAsFixed(2)} '
              '${_selectedInvoice!.dueDate != null ? "is due on ${_selectedInvoice!.dueDate}" : "is pending"}. '
              'Please let us know if you have any questions. Thank you, $biz.';
        } else {
          _messageController.text =
              'Hi $customerName, this is a friendly reminder regarding your pending payment. '
              'Please let us know if you have any questions. Thank you, $biz.';
        }
        break;
      case _MessageTemplate.paymentThanks:
        _messageController.text = 'Hi $customerName, thank you for your payment'
            '${_selectedInvoice != null ? " for invoice ${_selectedInvoice!.invoiceNumber}" : ""}. '
            'We appreciate your business! — $biz';
        break;
      case _MessageTemplate.custom:
        break;
    }
  }

  String? _sanitizedPhone(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return null;
    // Strip everything except digits
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    // If it looks like a 10-digit Indian number without country code, prefix +91
    if (digits.length == 10) {
      return '91$digits';
    }
    return digits;
  }

  Future<void> _sendWhatsAppMessage() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a customer'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final phone = _sanitizedPhone(_selectedCustomer!.phone);
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This customer has no valid phone number saved'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Message cannot be empty'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final encodedMessage = Uri.encodeComponent(_messageController.text.trim());
    final uri = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('WhatsApp is not installed on this device'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer selection
            BlocBuilder<CustomerBloc, CustomerState>(
              builder: (context, state) {
                if (state is CustomerLoaded) {
                  return DropdownButtonFormField<CustomerEntity>(
                    decoration: const InputDecoration(
                      labelText: 'Select Customer *',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCustomer,
                    items: state.customers.map((customer) {
                      return DropdownMenuItem(
                        value: customer,
                        child: Text(
                          '${customer.name}'
                          '${customer.phone != null ? " (${customer.phone})" : " (no phone)"}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomer = value;
                        _selectedInvoice = null;
                      });
                      _rebuildMessage();
                    },
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 16),

            // Invoice selection (optional, for reminder context)
            if (_selectedCustomer != null)
              BlocBuilder<InvoiceBloc, InvoiceState>(
                builder: (context, state) {
                  if (state is InvoiceLoaded) {
                    final customerInvoices = state.invoices
                        .where((inv) => inv.customerId == _selectedCustomer!.id)
                        .toList();

                    if (customerInvoices.isEmpty) return const SizedBox();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DropdownButtonFormField<InvoiceEntity?>(
                        decoration: const InputDecoration(
                          labelText: 'Related Invoice (optional)',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedInvoice,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('None'),
                          ),
                          ...customerInvoices.map((invoice) {
                            return DropdownMenuItem(
                              value: invoice,
                              child: Text(
                                '${invoice.invoiceNumber} — Rs${invoice.total.toStringAsFixed(2)} (${invoice.status})',
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedInvoice = value);
                          _rebuildMessage();
                        },
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),

            const Text(
              'Message Template',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Invoice Reminder'),
                  selected: _template == _MessageTemplate.invoiceReminder,
                  onSelected: (_) {
                    setState(
                        () => _template = _MessageTemplate.invoiceReminder);
                    _rebuildMessage();
                  },
                ),
                ChoiceChip(
                  label: const Text('Payment Thanks'),
                  selected: _template == _MessageTemplate.paymentThanks,
                  onSelected: (_) {
                    setState(() => _template = _MessageTemplate.paymentThanks);
                    _rebuildMessage();
                  },
                ),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: _template == _MessageTemplate.custom,
                  onSelected: (_) {
                    setState(() => _template = _MessageTemplate.custom);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            CustomButton(
              text: 'Send via WhatsApp',
              icon: Icons.chat,
              onPressed: _sendWhatsAppMessage,
            ),
          ],
        ),
      ),
    );
  }
}
