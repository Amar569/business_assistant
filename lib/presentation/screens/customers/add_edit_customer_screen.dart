import 'package:business_assistant/presentation/bloc/customer/customer_event.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_state.dart';
import 'package:business_assistant/presentation/screens/widgets/custom_button.dart';
import 'package:business_assistant/presentation/screens/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_bloc.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/core/utils/helpers.dart';
import 'package:business_assistant/core/utils/validators.dart';
class AddEditCustomerScreen extends StatefulWidget {
  final CustomerEntity? customer;

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _gstinController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _emailController =
        TextEditingController(text: widget.customer?.email ?? '');
    _phoneController =
        TextEditingController(text: widget.customer?.phone ?? '');
    _addressController =
        TextEditingController(text: widget.customer?.address ?? '');
    _gstinController =
        TextEditingController(text: widget.customer?.gstin ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.customer != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Customer' : 'Add Customer'),
      ),
      body: BlocListener<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            setState(() => _isLoading = false);
            Navigator.pop(context, true);
          }
          if (state is CustomerError) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CustomTextField(
                  label: 'Name *',
                  controller: _nameController,
                  validator: (value) =>
                      Validators.validateRequired(value, 'Name'),
                  prefixIcon: Icons.person,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  controller: _emailController,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return Validators.validateEmail(value);
                    }
                    return null;
                  },
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone',
                  controller: _phoneController,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return Validators.validatePhone(value);
                    }
                    return null;
                  },
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Address',
                  controller: _addressController,
                  maxLines: 3,
                  prefixIcon: Icons.location_on,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'GSTIN',
                  controller: _gstinController,
                  validator: Validators.validateGSTIN,
                  prefixIcon: Icons.business,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: _isLoading
                      ? 'Saving...'
                      : (isEdit ? 'Update Customer' : 'Add Customer'),
                  onPressed: _isLoading ? null : _submitForm,
                  isLoading: _isLoading,
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    isOutlined: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final customer = CustomerEntity(
        id: widget.customer?.id ?? Helpers.generateId(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        gstin: _gstinController.text.trim().isEmpty
            ? null
            : _gstinController.text.trim(),
        outstandingBalance: widget.customer?.outstandingBalance ?? 0,
        createdAt: widget.customer?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.customer != null) {
        context.read<CustomerBloc>().add(UpdateCustomer(customer));
      } else {
        context.read<CustomerBloc>().add(AddCustomer(customer));
      }
    }
  }
}
