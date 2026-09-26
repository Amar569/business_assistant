import 'package:business_assistant/presentation/bloc/customer/customer_event.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_bloc.dart';
import 'package:business_assistant/presentation/screens/customers/add_edit_customer_screen.dart';
import 'package:business_assistant/presentation/screens/customers/customer_detail_screen.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/core/utils/helpers.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEditScreen(CustomerEntity customer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditCustomerScreen(customer: customer),
      ),
    );
    if (mounted) {
      context.read<CustomerBloc>().add(LoadCustomers());
    }
  }

  Future<void> _openDetailScreen(CustomerEntity customer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customer: customer),
      ),
    );
    if (mounted) {
      context.read<CustomerBloc>().add(LoadCustomers());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CustomerBloc>().add(LoadCustomers());
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddEditCustomerScreen()),
              ).then((_) {
                context.read<CustomerBloc>().add(LoadCustomers());
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                context.read<CustomerBloc>().add(SearchCustomers(value));
              },
            ),
          ),
        ),
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is CustomerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CustomerLoaded) {
            final customers = state.filteredCustomers;
            if (customers.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<CustomerBloc>().add(LoadCustomers());
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        'No customers found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<CustomerBloc>().add(LoadCustomers());
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Text(
                          Helpers.getInitials(customer.name),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(customer.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (customer.phone != null) Text(customer.phone!),
                          if (customer.email != null)
                            Text(customer.email!,
                                style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Rs${customer.outstandingBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: customer.outstandingBalance > 0
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (customer.outstandingBalance > 0)
                            const Text(
                              'Pending',
                              style: TextStyle(fontSize: 10, color: Colors.red),
                            ),
                        ],
                      ),
                      onTap: () => _openDetailScreen(customer),
                      onLongPress: () {
                        _showCustomerOptions(context, customer);
                      },
                    ),
                  );
                },
              ),
            );
          }
          if (state is CustomerError) {
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
                      context.read<CustomerBloc>().add(LoadCustomers());
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

  void _showCustomerOptions(BuildContext context, CustomerEntity customer) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Customer'),
                onTap: () {
                  Navigator.pop(context);
                  _openEditScreen(customer);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Customer',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, customer.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String customerId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: const Text('Are you sure you want to delete this customer?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<CustomerBloc>().add(DeleteCustomer(customerId));
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
