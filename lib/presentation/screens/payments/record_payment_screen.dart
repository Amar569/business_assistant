import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_state.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_bloc.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_state.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_bloc.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_event.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_state.dart';
import 'package:business_assistant/presentation/screens/widgets/custom_button.dart';
import 'package:business_assistant/presentation/screens/widgets/custom_text_field.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:business_assistant/domain/entities/payment_entity.dart';
import 'package:business_assistant/core/utils/helpers.dart';
import 'package:business_assistant/core/constants/app_constants.dart';

class RecordPaymentScreen extends StatefulWidget {
  final InvoiceEntity? invoice; // optional preselected invoice

  const RecordPaymentScreen({super.key, this.invoice});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  CustomerEntity? _selectedCustomer;
  InvoiceEntity? _selectedInvoice;
  String _paymentMethod = AppConstants.paymentMethods.first;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _transactionIdController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = Helpers.formatDate(DateTime.now());

    if (widget.invoice != null) {
      _selectedInvoice = widget.invoice;
      _amountController.text = widget.invoice!.total.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _transactionIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = Helpers.formatDate(picked);
      });
    }
  }

  void _submitPayment() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a customer'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedInvoice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select an invoice'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid amount'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payment = PaymentEntity(
      id: Helpers.generateId(),
      invoiceId: _selectedInvoice!.id,
      customerId: _selectedCustomer!.id,
      amount: amount,
      paymentDate: DateTime.now(),
      paymentMethod: _paymentMethod,
      transactionId: _transactionIdController.text.trim().isEmpty
          ? null
          : _transactionIdController.text.trim(),
      status: 'Completed',
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    context.read<PaymentBloc>().add(AddPayment(payment));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _submitPayment,
          ),
        ],
      ),
      body: BlocListener<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentOperationSuccess) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context, true);
          }
          if (state is PaymentError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Selection
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
                            child: Text(customer.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCustomer = value;
                            _selectedInvoice = null; // reset invoice choice
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a customer' : null,
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 16),

                // Invoice Selection (filtered by selected customer)
                BlocBuilder<InvoiceBloc, InvoiceState>(
                  builder: (context, state) {
                    if (_selectedCustomer == null) {
                      return const SizedBox();
                    }
                    if (state is InvoiceLoaded) {
                      final customerInvoices = state.invoices
                          .where((inv) =>
                              inv.customerId == _selectedCustomer!.id &&
                              inv.status != 'Paid' &&
                              inv.status != 'Cancelled')
                          .toList();

                      if (customerInvoices.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No outstanding invoices for this customer',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return DropdownButtonFormField<InvoiceEntity>(
                        decoration: const InputDecoration(
                          labelText: 'Select Invoice *',
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
                            }
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select an invoice' : null,
                      );
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Amount *',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _pickDate,
                  child: AbsorbPointer(
                    child: CustomTextField(
                      label: 'Payment Date',
                      controller: _dateController,
                      readOnly: true,
                      prefixIcon: Icons.calendar_today,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Payment Method *',
                    border: OutlineInputBorder(),
                  ),
                  value: _paymentMethod,
                  items: AppConstants.paymentMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _paymentMethod = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Transaction ID (optional)',
                  controller: _transactionIdController,
                  prefixIcon: Icons.confirmation_number,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Notes (optional)',
                  controller: _notesController,
                  maxLines: 3,
                  prefixIcon: Icons.note,
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: _isLoading ? 'Recording Payment...' : 'Record Payment',
                  onPressed: _isLoading ? null : _submitPayment,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
