// import 'package:flutter/material.dart';

// class PaymentListScreen extends StatelessWidget {
//   const PaymentListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Payments')),
//       body: const Center(
//         child: Text('Payment List Screen'),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_bloc.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_event.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_state.dart';
import 'package:business_assistant/domain/entities/payment_entity.dart';
import 'package:business_assistant/presentation/screens/payments/record_payment_screen.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(LoadPayments());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PaymentBloc>().add(LoadPayments());
            },
          ),
        ],
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PaymentLoaded) {
            final payments = state.payments;
            if (payments.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PaymentBloc>().add(LoadPayments());
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Icon(Icons.payments_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Center(
                      child: Text(
                        'No payments recorded yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<PaymentBloc>().add(LoadPayments());
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final PaymentEntity payment = payments[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.payments,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      title: Text(
                        'Rs${payment.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(payment.paymentMethod),
                          Text(
                            '${payment.paymentDate.day}/${payment.paymentDate.month}/${payment.paymentDate.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (payment.transactionId != null)
                            Text(
                              'Txn: ${payment.transactionId}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
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
              ),
            );
          }
          if (state is PaymentError) {
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
                      context.read<PaymentBloc>().add(LoadPayments());
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RecordPaymentScreen()),
          );
          if (context.mounted) {
            context.read<PaymentBloc>().add(LoadPayments());
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
