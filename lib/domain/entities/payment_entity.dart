import 'package:equatable/equatable.dart';

class PaymentEntity extends Equatable {
  final String id;
  final String invoiceId;
  final String customerId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? transactionId;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PaymentEntity({
    required this.id,
    required this.invoiceId,
    required this.customerId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.transactionId,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        invoiceId,
        customerId,
        amount,
        paymentDate,
        paymentMethod,
        transactionId,
        status,
        notes,
        createdAt,
        updatedAt,
      ];
}
