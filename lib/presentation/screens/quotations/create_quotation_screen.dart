import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_state.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_bloc.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_event.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_state.dart';
import 'package:business_assistant/presentation/screens/widgets/custom_button.dart';
import 'package:business_assistant/presentation/screens/widgets/custom_text_field.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/domain/entities/quotation_entity.dart';
import 'package:business_assistant/core/utils/helpers.dart';
import 'package:business_assistant/core/constants/app_constants.dart';
import 'package:business_assistant/core/di/injection_container.dart';
import 'package:business_assistant/data/services/pdf_storage_service.dart';
import 'package:business_assistant/core/services/business_info_service.dart';

class CreateQuotationScreen extends StatefulWidget {
  final QuotationEntity? quotation; // present = editing an existing quotation

  const CreateQuotationScreen({super.key, this.quotation});

  @override
  State<CreateQuotationScreen> createState() => _CreateQuotationScreenState();
}

class _CreateQuotationScreenState extends State<CreateQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  CustomerEntity? _selectedCustomer;
  double _subtotal = 0;
  double _taxRate = 18;
  double _tax = 0;
  double _total = 0;

  final List<QuotationItemEntity> _items = [];
  final List<TextEditingController> _descControllers = [];
  final List<TextEditingController> _qtyControllers = [];
  final List<TextEditingController> _rateControllers = [];

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _validUntilController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  bool get _isEditing => widget.quotation != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final quotation = widget.quotation!;
      _dateController.text = quotation.date;
      _validUntilController.text = quotation.validUntil ?? '';
      _notesController.text = quotation.notes ?? '';
      _taxRate = quotation.taxRate;
      _subtotal = quotation.subtotal;
      _tax = quotation.tax;
      _total = quotation.total;

      for (final item in quotation.items) {
        _items.add(item);
        _descControllers.add(TextEditingController(text: item.description));
        _qtyControllers
            .add(TextEditingController(text: item.quantity.toString()));
        _rateControllers.add(TextEditingController(text: item.rate.toString()));
      }
    } else {
      _dateController.text = Helpers.formatDate(DateTime.now());
      _validUntilController.text =
          Helpers.formatDate(DateTime.now().add(const Duration(days: 30)));
      _addItem();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _validUntilController.dispose();
    _notesController.dispose();
    for (final c in _descControllers) {
      c.dispose();
    }
    for (final c in _qtyControllers) {
      c.dispose();
    }
    for (final c in _rateControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(QuotationItemEntity(
        id: Helpers.generateId(),
        description: '',
        quantity: 1,
        rate: 0,
        amount: 0,
      ));
      _descControllers.add(TextEditingController());
      _qtyControllers.add(TextEditingController(text: '1'));
      _rateControllers.add(TextEditingController(text: '0'));
    });
  }

  void _removeItemById(String itemId) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    setState(() {
      _items.removeAt(index);
      _descControllers.removeAt(index).dispose();
      _qtyControllers.removeAt(index).dispose();
      _rateControllers.removeAt(index).dispose();
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    _subtotal = _items.fold(0, (sum, item) => sum + item.amount);
    _tax = (_subtotal * _taxRate) / 100;
    _total = _subtotal + _tax;
    setState(() {});
  }

  void _updateItem(int index,
      {String? description, int? quantity, double? rate}) {
    final item = _items[index];
    final newDescription = description ?? item.description;
    final newQuantity = quantity ?? item.quantity;
    final newRate = rate ?? item.rate;
    final newAmount = newQuantity * newRate;

    setState(() {
      _items[index] = QuotationItemEntity(
        id: item.id,
        description: newDescription,
        quantity: newQuantity,
        rate: newRate,
        amount: newAmount,
      );
    });
    _calculateTotals();
  }

  Future<void> _submitQuotation() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a customer'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (_items.isEmpty || _items.every((item) => item.amount == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please add at least one item'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final quotation = QuotationEntity(
      id: _isEditing ? widget.quotation!.id : Helpers.generateId(),
      quotationNumber: _isEditing
          ? widget.quotation!.quotationNumber
          : Helpers.generateQuotationNumber(),
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      date: _dateController.text,
      validUntil: _validUntilController.text,
      subtotal: _subtotal,
      tax: _tax,
      taxRate: _taxRate,
      total: _total,
      status: _isEditing ? widget.quotation!.status : 'Draft',
      items: _items,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: _isEditing ? widget.quotation!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (_isEditing) {
      context.read<QuotationBloc>().add(UpdateQuotation(quotation));
    } else {
      context.read<QuotationBloc>().add(AddQuotation(quotation));
    }

    // Generate and save the PDF using the same entity we just built
    try {
      final businessInfo = await BusinessInfoService.load();

      await getIt<PdfStorageService>().generateAndSaveQuotationPdf(
        quotation: quotation,
        customer: _selectedCustomer!,
        businessInfo: businessInfo,
      );
    } catch (e) {
      debugPrint('Quotation PDF generation failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve the selected customer from CustomerBloc's state when editing,
    // since QuotationEntity only stores customerId/customerName, not the
    // full CustomerEntity object.
    if (_isEditing && _selectedCustomer == null) {
      final customerState = context.read<CustomerBloc>().state;
      if (customerState is CustomerLoaded) {
        try {
          _selectedCustomer = customerState.customers
              .firstWhere((c) => c.id == widget.quotation!.customerId);
        } catch (_) {
          _selectedCustomer = null;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Quotation' : 'Create Quotation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _submitQuotation,
          ),
        ],
      ),
      body: BlocListener<QuotationBloc, QuotationState>(
        listener: (context, state) {
          if (state is QuotationOperationSuccess) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
          if (state is QuotationError) {
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
                          setState(() => _selectedCustomer = value);
                        },
                        validator: (value) =>
                            value == null ? 'Please select a customer' : null,
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 16),

                // Dates
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Date',
                        controller: _dateController,
                        readOnly: true,
                        prefixIcon: Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Valid Until',
                        controller: _validUntilController,
                        readOnly: true,
                        prefixIcon: Icons.event_busy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // GST Rate
                DropdownButtonFormField<double>(
                  decoration: const InputDecoration(
                    labelText: 'GST Rate',
                    border: OutlineInputBorder(),
                  ),
                  value: _taxRate,
                  items: AppConstants.gstRates.map((rate) {
                    return DropdownMenuItem(value: rate, child: Text('$rate%'));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _taxRate = value;
                        _calculateTotals();
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Items
                const Text(
                  'Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Card(
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _descControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: InputBorder.none,
                              ),
                              onChanged: (value) =>
                                  _updateItem(index, description: value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _qtyControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Qty',
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final qty = int.tryParse(value) ?? 0;
                                _updateItem(index, quantity: qty);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _rateControllers[index],
                              decoration: const InputDecoration(
                                labelText: 'Rate',
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final rate = double.tryParse(value) ?? 0;
                                _updateItem(index, rate: rate);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rs${item.amount.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.red),
                            onPressed: _items.length > 1
                                ? () => _removeItemById(item.id)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                CustomButton(
                  text: 'Add Item',
                  onPressed: _addItem,
                  isOutlined: true,
                ),
                const SizedBox(height: 16),

                // Totals
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text('Rs${_subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tax ($_taxRate%):'),
                          Text('Rs${_tax.toStringAsFixed(2)}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Rs${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Notes',
                  controller: _notesController,
                  maxLines: 3,
                  prefixIcon: Icons.note,
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: _isLoading
                      ? (_isEditing
                          ? 'Updating Quotation...'
                          : 'Creating Quotation...')
                      : (_isEditing ? 'Update Quotation' : 'Create Quotation'),
                  onPressed: _isLoading ? null : _submitQuotation,
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
