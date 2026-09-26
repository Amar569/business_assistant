import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_bloc.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_state.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_bloc.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_state.dart';
import 'package:business_assistant/presentation/screens/customers/add_edit_customer_screen.dart';
import 'package:business_assistant/presentation/screens/payments/record_payment_screen.dart';
import 'package:business_assistant/presentation/screens/invoices/create_invoice_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final CustomerEntity customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditCustomerScreen(customer: customer),
                ),
              );
              // Note: since customer is passed as a value, edits made
              // won't reflect here until you go back to the list and
              // reopen this screen. See note below for a live-refresh option.
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Invoices'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Customer profile summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.15),
                      child: Text(
                        customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (customer.phone != null)
                            Text(customer.phone!,
                                style: const TextStyle(fontSize: 13)),
                          if (customer.email != null)
                            Text(customer.email!,
                                style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Outstanding',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          'Rs${customer.outstandingBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: customer.outstandingBalance > 0
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (customer.address != null || customer.gstin != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  if (customer.address != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            customer.address!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  if (customer.gstin != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.business,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'GSTIN: ${customer.gstin}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: const Text('New Invoice'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CreateInvoiceScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.payment, size: 18),
                        label: const Text('Record Payment'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RecordPaymentScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs: Invoices / Payments
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInvoicesTab(customer),
                _buildPaymentsTab(customer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab(CustomerEntity customer) {
    return BlocBuilder<InvoiceBloc, InvoiceState>(
      builder: (context, state) {
        if (state is InvoiceLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is InvoiceLoaded) {
          final invoices = state.invoices
              .where((inv) => inv.customerId == customer.id)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (invoices.isEmpty) {
            return const Center(
              child: Text(
                'No invoices for this customer yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.receipt_long,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: Text(invoice.invoiceNumber),
                  subtitle: Text(
                    '${invoice.date}${invoice.dueDate != null ? ' • Due ${invoice.dueDate}' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Rs${invoice.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(invoice.status).withOpacity(0.15),
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
                ),
              );
            },
          );
        }
        if (state is InvoiceError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildPaymentsTab(CustomerEntity customer) {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, state) {
        if (state is PaymentLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is PaymentLoaded) {
          final payments = state.payments
              .where((p) => p.customerId == customer.id)
              .toList()
            ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

          if (payments.isEmpty) {
            return const Center(
              child: Text(
                'No payments recorded for this customer yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.payments,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: Text('Rs${payment.amount.toStringAsFixed(2)}'),
                  subtitle: Text(
                    '${payment.paymentMethod} • '
                    '${payment.paymentDate.day}/${payment.paymentDate.month}/${payment.paymentDate.year}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(payment.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      payment.status,
                      style: TextStyle(
                        fontSize: 11,
                        color: _statusColor(payment.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
        if (state is PaymentError) {
          return Center(child: Text(state.message));
        }
        return const SizedBox();
      },
    );
  }
}
