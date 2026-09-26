import 'package:business_assistant/core/di/injection_container.dart';
import 'package:business_assistant/data/services/backup_service.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_event.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_bloc.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_event.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_bloc.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_event.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_bloc.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_event.dart';
import 'package:business_assistant/presentation/screens/widgets/custom_button.dart';
import 'package:business_assistant/presentation/screens/widgets/custom_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_assistant/core/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _bankDetailsController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _upiIdController.dispose();
    _bankDetailsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _businessNameController.text =
          prefs.getString(AppConstants.prefBusinessName) ?? '';
      _gstinController.text = prefs.getString(AppConstants.prefGstin) ?? '';
      _addressController.text =
          prefs.getString(AppConstants.prefBusinessAddress) ?? '';
      _phoneController.text =
          prefs.getString(AppConstants.prefBusinessPhone) ?? '';
      _emailController.text =
          prefs.getString(AppConstants.prefBusinessEmail) ?? '';
      _upiIdController.text = prefs.getString(AppConstants.prefUpiId) ?? '';
      _bankDetailsController.text =
          prefs.getString(AppConstants.prefBankDetails) ?? '';
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.prefBusinessName, _businessNameController.text);
    await prefs.setString(AppConstants.prefGstin, _gstinController.text);
    await prefs.setString(
        AppConstants.prefBusinessAddress, _addressController.text);
    await prefs.setString(
        AppConstants.prefBusinessPhone, _phoneController.text);
    await prefs.setString(
        AppConstants.prefBusinessEmail, _emailController.text);
    await prefs.setString(AppConstants.prefUpiId, _upiIdController.text);
    await prefs.setString(
        AppConstants.prefBankDetails, _bankDetailsController.text);

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green),
    );
  }

    Future<void> _exportBackup() async {
    try {
      final backupService = getIt<BackupService>();
      final path = await backupService.exportBackup();

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Business Assistant Backup',
        text: 'Backup created on ${DateTime.now()}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Backup failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Restore Backup'),
          content: const Text(
            'This will replace all existing data with the backup contents. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final backupService = getIt<BackupService>();
      await backupService.restoreBackup(result.files.single.path!,
          merge: false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Backup restored successfully'),
            backgroundColor: Colors.green),
      );

      // Reload all blocs so the UI reflects the restored data
      context.read<CustomerBloc>().add(LoadCustomers());
      context.read<InvoiceBloc>().add(LoadInvoices());
      context.read<PaymentBloc>().add(LoadPayments());
      context.read<QuotationBloc>().add(LoadQuotations());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Restore failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Business Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Business Name',
                controller: _businessNameController,
                prefixIcon: Icons.business,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'GSTIN',
                controller: _gstinController,
                prefixIcon: Icons.business_center,
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
                label: 'Phone',
                controller: _phoneController,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'UPI ID',
                controller: _upiIdController,
                prefixIcon: Icons.payment,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Bank Details',
                controller: _bankDetailsController,
                maxLines: 3,
                prefixIcon: Icons.account_balance,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _isLoading ? 'Saving...' : 'Save Settings',
                onPressed: _isLoading ? null : _saveSettings,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
