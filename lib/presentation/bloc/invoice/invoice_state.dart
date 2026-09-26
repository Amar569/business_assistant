import 'package:equatable/equatable.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';

abstract class InvoiceState extends Equatable {
  const InvoiceState();

  @override
  List<Object?> get props => [];
}

class InvoiceInitial extends InvoiceState {}

class InvoiceLoading extends InvoiceState {}

class InvoiceLoaded extends InvoiceState {
  final List<InvoiceEntity> invoices;
  final List<InvoiceEntity> filteredInvoices;
  final String? currentFilter;

  const InvoiceLoaded({
    required this.invoices,
    required this.filteredInvoices,
    this.currentFilter,
  });

  @override
  List<Object?> get props => [invoices, filteredInvoices, currentFilter];
}

class InvoiceOperationSuccess extends InvoiceState {
  final String message;

  const InvoiceOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class InvoiceError extends InvoiceState {
  final String message;

  const InvoiceError(this.message);

  @override
  List<Object?> get props => [message];
}
