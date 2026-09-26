import 'package:equatable/equatable.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';

abstract class InvoiceEvent extends Equatable {
  const InvoiceEvent();

  @override
  List<Object?> get props => [];
}

class LoadInvoices extends InvoiceEvent {}

class AddInvoice extends InvoiceEvent {
  final InvoiceEntity invoice;

  const AddInvoice(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class UpdateInvoice extends InvoiceEvent {
  final InvoiceEntity invoice;

  const UpdateInvoice(this.invoice);

  @override
  List<Object?> get props => [invoice];
}

class DeleteInvoice extends InvoiceEvent {
  final String invoiceId;

  const DeleteInvoice(this.invoiceId);

  @override
  List<Object?> get props => [invoiceId];
}

class FilterInvoicesByStatus extends InvoiceEvent {
  final String status;

  const FilterInvoicesByStatus(this.status);

  @override
  List<Object?> get props => [status];
}
