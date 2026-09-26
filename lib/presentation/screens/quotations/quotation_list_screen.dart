import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_bloc.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_event.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_state.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_bloc.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_event.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_state.dart';
import 'package:business_assistant/domain/entities/quotation_entity.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/core/utils/quotation_converter.dart';
import 'package:business_assistant/core/di/injection_container.dart';
import 'package:business_assistant/data/services/pdf_storage_service.dart';
import 'package:business_assistant/core/services/business_info_service.dart';
import 'package:business_assistant/presentation/screens/quotations/create_quotation_screen.dart';

class QuotationListScreen extends StatelessWidget {
  const QuotationListScreen({super.key});

  static const List<String> _terminalStatuses = [
    'Accepted',
    'Rejected',
    'Expired',
    'Converted',
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Expired':
        return Colors.grey;
      case 'Sent':
        return Colors.blue;
      case 'Converted':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  List<String> _validNextQuotationStatuses(String current) {
    switch (current) {
      case 'Draft':
        return ['Sent'];
      case 'Sent':
        return ['Accepted', 'Rejected', 'Expired'];
      default:
        return []; // Accepted, Rejected, Expired, Converted are terminal
    }
  }

  Future<void> _changeQuotationStatus(
      BuildContext context, QuotationEntity quotation, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Status'),
        content: Text(
          'Change quotation ${quotation.quotationNumber} status from '
          '"${quotation.status}" to "$newStatus"?',
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

    final updatedQuotation = QuotationEntity(
      id: quotation.id,
      quotationNumber: quotation.quotationNumber,
      customerId: quotation.customerId,
      customerName: quotation.customerName,
      date: quotation.date,
      validUntil: quotation.validUntil,
      subtotal: quotation.subtotal,
      tax: quotation.tax,
      taxRate: quotation.taxRate,
      total: quotation.total,
      status: newStatus,
      items: quotation.items,
      notes: quotation.notes,
      createdAt: quotation.createdAt,
      updatedAt: DateTime.now(),
    );

    context.read<QuotationBloc>().add(UpdateQuotation(updatedQuotation));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status changed to $newStatus'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _convertToInvoice(
      BuildContext context, QuotationEntity quotation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Convert to Invoice'),
        content: Text(
          'Create a new invoice from "${quotation.quotationNumber}" for '
          '${quotation.customerName}? This will not delete the quotation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Convert'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final invoice = QuotationConverter.toInvoice(quotation);
    context.read<InvoiceBloc>().add(AddInvoice(invoice));

    final updatedQuotation = QuotationEntity(
      id: quotation.id,
      quotationNumber: quotation.quotationNumber,
      customerId: quotation.customerId,
      customerName: quotation.customerName,
      date: quotation.date,
      validUntil: quotation.validUntil,
      subtotal: quotation.subtotal,
      tax: quotation.tax,
      taxRate: quotation.taxRate,
      total: quotation.total,
      status: 'Converted',
      items: quotation.items,
      notes: quotation.notes,
      createdAt: quotation.createdAt,
      updatedAt: DateTime.now(),
    );
    context.read<QuotationBloc>().add(UpdateQuotation(updatedQuotation));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Invoice ${invoice.invoiceNumber} created from quotation'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _editQuotation(
      BuildContext context, QuotationEntity quotation) async {
    if (_terminalStatuses.contains(quotation.status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${quotation.status} quotations cannot be edited.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CreateQuotationScreen(quotation: quotation)),
    );
    if (context.mounted) {
      context.read<QuotationBloc>().add(LoadQuotations());
    }
  }

  // Looks up the full CustomerEntity from CustomerBloc's current state,
  // regenerates the quotation PDF, and opens it for viewing/sharing.
  // Future<void> _viewOrSharePdf(
  //     BuildContext context, QuotationEntity quotation) async {
  //   final customerState = context.read<CustomerBloc>().state;

  //   CustomerEntity? customer;
  //   if (customerState is CustomerLoaded) {
  //     try {
  //       customer = customerState.customers
  //           .firstWhere((c) => c.id == quotation.customerId);
  //     } catch (_) {
  //       customer = null;
  //     }
  //   }

  //   if (customer == null) {
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //             content:
  //                 Text('Could not find customer details for this quotation'),
  //             backgroundColor: Colors.red),
  //       );
  //     }
  //     return;
  //   }

  //   try {
  //     final businessInfo = await BusinessInfoService.load();
  //     final file = await getIt<PdfStorageService>().generateAndSaveQuotationPdf(
  //       quotation: quotation,
  //       customer: customer,
  //       businessInfo: businessInfo,
  //     );

  //     await Printing.sharePdf(
  //       bytes: await file.readAsBytes(),
  //       filename: '${quotation.quotationNumber}.pdf',
  //     );
  //   } catch (e) {
  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //             content: Text('Failed to generate PDF: $e'),
  //             backgroundColor: Colors.red),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<QuotationBloc>().add(LoadQuotations());
            },
          ),
        ],
      ),
      body: BlocConsumer<QuotationBloc, QuotationState>(
        listener: (context, state) {
          if (state is QuotationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is QuotationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is QuotationLoaded) {
            if (state.quotations.isEmpty) {
              return const Center(child: Text('No quotations yet'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.quotations.length,
              itemBuilder: (context, index) {
                final quotation = state.quotations[index];
                final alreadyConverted = quotation.status == 'Converted';
                final isTerminal = _terminalStatuses.contains(quotation.status);
                final nextStatuses =
                    _validNextQuotationStatuses(quotation.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(quotation.quotationNumber),
                    subtitle:
                        Text('${quotation.customerName} • ${quotation.date}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Rs${quotation.total.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _statusColor(quotation.status)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                quotation.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _statusColor(quotation.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        PopupMenuButton<String>(
                          // onSelected: (value) {
                          //   if (value == 'edit') {
                          //     _editQuotation(context, quotation);
                          //   } else if (value == 'convert') {
                          //     _convertToInvoice(context, quotation);
                          //   } else if (value == 'pdf') {
                          //     _viewOrSharePdf(context, quotation);
                          //   } else if (nextStatuses.contains(value)) {
                          //     _changeQuotationStatus(context, quotation, value);
                          //   }
                          // },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              enabled: !isTerminal,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: isTerminal ? Colors.grey : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isTerminal
                                        ? '${quotation.status} (locked)'
                                        : 'Edit',
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'pdf',
                              child: Row(
                                children: [
                                  Icon(Icons.picture_as_pdf, size: 20),
                                  SizedBox(width: 8),
                                  Text('View/Share PDF'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'convert',
                              enabled: !alreadyConverted,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long,
                                    size: 20,
                                    color:
                                        alreadyConverted ? Colors.grey : null,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    alreadyConverted
                                        ? 'Already Converted'
                                        : 'Convert to Invoice',
                                  ),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          if (state is QuotationError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
          );
          if (context.mounted) {
            context.read<QuotationBloc>().add(LoadQuotations());
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
