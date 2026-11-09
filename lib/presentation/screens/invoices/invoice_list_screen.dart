import 'package:business_assistant/core/di/injection_container.dart';
import 'package:business_assistant/core/services/business_info_service.dart';
import 'package:business_assistant/data/services/pdf_storage_service.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_bloc.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_event.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_state.dart';
import 'package:business_assistant/core/constants/app_constants.dart';
import 'package:business_assistant/presentation/screens/invoices/create_invoice_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(LoadInvoices());
  }

  List<String> _validNextStatuses(String current) {
    switch (current) {
      case 'Draft':
        return ['Sent', 'Cancelled'];
      case 'Sent':
        return ['Paid', 'Overdue', 'Cancelled'];
      case 'Overdue':
        return ['Paid', 'Cancelled'];
      case 'Paid':
      case 'Cancelled':
        return []; // terminal states — no further manual transition
      default:
        return AppConstants.invoiceStatus;
    }
  }

  Future<void> _changeInvoiceStatus(
      BuildContext context, InvoiceEntity invoice, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Status'),
        content: Text(
          'Change invoice ${invoice.invoiceNumber} status from '
          '"${invoice.status}" to "$newStatus"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final updatedInvoice = InvoiceEntity(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      customerId: invoice.customerId,
      date: invoice.date,
      dueDate: invoice.dueDate,
      subtotal: invoice.subtotal,
      tax: invoice.tax,
      taxRate: invoice.taxRate,
      total: invoice.total,
      status: newStatus,
      items: invoice.items,
      notes: invoice.notes,
      createdAt: invoice.createdAt,
      updatedAt: DateTime.now(),
    );

    context.read<InvoiceBloc>().add(UpdateInvoice(updatedInvoice));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status changed to $newStatus'),
        backgroundColor: Colors.green,
      ),
    );

    // Regenerate the PDF so Documents reflects the new status
    final customerState = context.read<CustomerBloc>().state;
    CustomerEntity? customer;
    if (customerState is CustomerLoaded) {
      try {
        customer = customerState.customers
            .firstWhere((c) => c.id == updatedInvoice.customerId);
      } catch (_) {
        customer = null;
      }
    }

    if (customer != null) {
      try {
        final businessInfo = await BusinessInfoService.load();
        await getIt<PdfStorageService>().generateAndSaveInvoicePdf(
          invoice: updatedInvoice,
          customer: customer,
          businessInfo: businessInfo,
        );
      } catch (e) {
        debugPrint('Failed to regenerate PDF after status change: $e');
      }
    }
  }

  Future<void> _editInvoice(BuildContext context, InvoiceEntity invoice) async {
    if (invoice.status == 'Paid' || invoice.status == 'Cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${invoice.status} invoices cannot be edited.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateInvoiceScreen(invoice: invoice),
      ),
    );
    if (context.mounted) {
      context.read<InvoiceBloc>().add(LoadInvoices());
    }
  }

  Future<void> _deleteInvoice(
      BuildContext context, InvoiceEntity invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text(
          'Are you sure you want to delete invoice '
          '${invoice.invoiceNumber}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    context.read<InvoiceBloc>().add(DeleteInvoice(invoice.id));
  }

  Future<void> _shareInvoice(
  BuildContext context, InvoiceEntity invoice) async {
  final customerState = context.read<CustomerBloc>().state;
  CustomerEntity? customer;
  if (customerState is CustomerLoaded) {
    try {
      customer = customerState.customers
          .firstWhere((c) => c.id == invoice.customerId);
      } catch (_) {
        customer = null;
      }
    }

  if (customer == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not find customer details for this invoice'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    final businessInfo = await BusinessInfoService.load();
    final pdfFile =
        await getIt<PdfStorageService>().generateAndSaveInvoicePdf(
      invoice: invoice,
      customer: customer,
      businessInfo: businessInfo,
    );

  await Share.shareXFiles(
    [XFile(pdfFile.path, mimeType: 'application/pdf')],
      subject: 'Invoice ${invoice.invoiceNumber}',
  );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
 }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
        return Colors.green;
      case 'Overdue':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      case 'Sent':
        return Colors.blue;
      default:
        return Colors.orange; // Draft
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<InvoiceBloc>().add(LoadInvoices());
            },
          ),
        ],
      ),
      body: BlocConsumer<InvoiceBloc, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.green),
            );
          }
          if (state is InvoiceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is InvoiceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InvoiceLoaded) {
            final invoices = state.invoices;

            if (invoices.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<InvoiceBloc>().add(LoadInvoices());
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('No invoices yet')),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<InvoiceBloc>().add(LoadInvoices());
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: invoices.length,
                itemBuilder: (context, index) {
                  final invoice = invoices[index];
                  final nextStatuses = _validNextStatuses(invoice.status);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(invoice.invoiceNumber),
                      subtitle: Text(
                        '${invoice.date}  •  Rs${invoice.total.toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Rs${invoice.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _statusColor(invoice.status)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  invoice.status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _statusColor(invoice.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // IconButton(
                          //   icon: const Icon(Icons.share, size: 20),
                          //   tooltip: 'Share PDF',
                          //   onPressed: () => _shareInvoice(context, invoice),
                          // ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onSelected: (value) {
                            if (value == 'share') {
                              _shareInvoice(context, invoice);
                            } else if (value == 'delete') {
                              _deleteInvoice(context, invoice);
                            } else if (nextStatuses.contains(value)) {
                              _changeInvoiceStatus(context, invoice, value);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share, size: 20),
                                  SizedBox(width: 8),
                                  Text('Send as PDF'),
                                ],
                              ),
                            ),
                            if (nextStatuses.isNotEmpty) ...[
                              const PopupMenuDivider(),
                              ...nextStatuses.map(
                                (status) => PopupMenuItem(
                                  value: status,
                                  child: Text('Mark as $status'),
                                ),
                              ),
                            ],
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          ),
                        ],
                      ),
                      onTap: () => _editInvoice(context, invoice),
                    ),
                  );
                },
              ),
            );
          }

          if (state is InvoiceError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<InvoiceBloc>().add(LoadInvoices());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
