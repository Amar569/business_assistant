import 'package:business_assistant/presentation/bloc/customer/customer_event.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_state.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_event.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_state.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_event.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_state.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_bloc.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_bloc.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_bloc.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_bloc.dart';
import 'package:business_assistant/presentation/screens/customers/customer_list_screen.dart';
import 'package:business_assistant/presentation/screens/customers/add_edit_customer_screen.dart';
import 'package:business_assistant/presentation/screens/invoices/invoice_list_screen.dart';
import 'package:business_assistant/presentation/screens/invoices/create_invoice_screen.dart';
import 'package:business_assistant/presentation/screens/payments/payment_list_screen.dart';
import 'package:business_assistant/presentation/screens/payments/record_payment_screen.dart';
import 'package:business_assistant/presentation/screens/quotations/create_quotation_screen.dart';
import 'package:business_assistant/presentation/screens/qr_payment/qr_payment_screen.dart';
import 'package:business_assistant/presentation/screens/documents/documents_screen.dart';
import 'package:business_assistant/presentation/screens/whatsapp/whatsapp_screen.dart';
import 'package:business_assistant/presentation/screens/settings/settings_screen.dart';
import 'package:business_assistant/presentation/screens/quotations/quotation_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardContent(),
    const CustomerListScreen(),
    const QuotationListScreen(),
    const InvoiceListScreen(),
    const PaymentListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 1:
              context.read<CustomerBloc>().add(LoadCustomers());
              break;
            case 2:
              context.read<QuotationBloc>().add(LoadQuotations());
              break;
            case 3:
              context.read<InvoiceBloc>().add(LoadInvoices());
              break;
            case 4:
              context.read<PaymentBloc>().add(LoadPayments());
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Quotations',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Invoices',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Payments',
          ),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats Cards
              _buildStatsCards(),
              const SizedBox(height: 24),

              // Recent Customers
              const Text(
                'Recent Customers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height:
                    520, // fixed height — Quick Actions always sits right below this
                child: _buildRecentCustomers(),
              ),
              const SizedBox(height: 10),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildStatsCards() {
    return BlocBuilder<PaymentBloc, PaymentState>(
      builder: (context, paymentState) {
        return BlocBuilder<InvoiceBloc, InvoiceState>(
          builder: (context, invoiceState) {
            double todaysSales = 0;
            double pendingPayments = 0;

            if (paymentState is PaymentLoaded) {
              final now = DateTime.now();
              todaysSales = paymentState.payments
                  .where((p) =>
                      p.status == 'Completed' &&
                      p.paymentDate.year == now.year &&
                      p.paymentDate.month == now.month &&
                      p.paymentDate.day == now.day)
                  .fold<double>(0, (sum, p) => sum + p.amount);
            }

            if (invoiceState is InvoiceLoaded) {
              pendingPayments = invoiceState.invoices
                  .where(
                      (inv) => inv.status == 'Sent' || inv.status == 'Overdue')
                  .fold<double>(0, (sum, inv) => sum + inv.total);
            }

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: "Today's Sales",
                    value: 'Rs${todaysSales.toStringAsFixed(2)}',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Pending Payments',
                    value: 'Rs${pendingPayments.toStringAsFixed(2)}',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCustomers() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is CustomerLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CustomerLoaded) {
          final customers = [...state.filteredCustomers]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (customers.isEmpty) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No customers yet'),
                ),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: Text(customer.name[0].toUpperCase()),
                ),
                title: Text(customer.name),
                subtitle: Text(customer.phone ?? 'No phone'),
                trailing: Text(
                  'Rs${customer.outstandingBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: customer.outstandingBalance > 0
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  // Navigate to customer detail
                },
              );
            },
          );
        }
        if (state is CustomerError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.person_add,
        'label': 'New Customer',
        'onTap': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()),
          );
          if (context.mounted) {
            context.read<CustomerBloc>().add(LoadCustomers());
          }
        },
      },
      {
        'icon': Icons.receipt,
        'label': 'New Invoice',
        'onTap': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
          if (context.mounted) {
            context.read<InvoiceBloc>().add(LoadInvoices());
          }
        },
      },
      {
        'icon': Icons.description,
        'label': 'Quotation',
        'onTap': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateQuotationScreen()),
          );
          if (context.mounted) {
            context.read<QuotationBloc>().add(LoadQuotations());
          }
        },
      },
      {
        'icon': Icons.payment,
        'label': 'Record Payment',
        'onTap': () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecordPaymentScreen()),
          );
          if (context.mounted) {
            context.read<PaymentBloc>().add(LoadPayments());
          }
        },
      },
      {
        'icon': Icons.qr_code,
        'label': 'QR Payment',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrPaymentScreen()),
            ),
      },
      {
        'icon': Icons.chat,
        'label': 'WhatsApp',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WhatsAppScreen()),
            ),
      },
      {
        'icon': Icons.folder,
        'label': 'Documents',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DocumentsScreen()),
            ),
      },
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'onTap': () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          elevation: 1,
          child: InkWell(
            onTap: action['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    action['icon'] as IconData,
                    size: 28,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
