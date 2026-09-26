import 'package:equatable/equatable.dart';

class InvoiceEntity extends Equatable {
  final String id;
  final String invoiceNumber;
  final String customerId;
  final String date;
  final String? dueDate;
  final double subtotal;
  final double tax;
  final double taxRate;
  final double total;
  final String status;
  final List<InvoiceItemEntity> items;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.date,
    this.dueDate,
    required this.subtotal,
    required this.tax,
    required this.taxRate,
    required this.total,
    required this.status,
    required this.items,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        customerId,
        date,
        dueDate,
        subtotal,
        tax,
        taxRate,
        total,
        status,
        items,
        notes,
        createdAt,
        updatedAt,
      ];
}

class InvoiceItemEntity extends Equatable {
  final String id;
  final String description;
  final int quantity;
  final double rate;
  final double amount;

  const InvoiceItemEntity({
    required this.id,
    required this.description,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  @override
  List<Object?> get props => [id, description, quantity, rate, amount];
}
