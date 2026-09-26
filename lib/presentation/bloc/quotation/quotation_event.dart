import 'package:equatable/equatable.dart';
import 'package:business_assistant/domain/entities/quotation_entity.dart';

abstract class QuotationEvent extends Equatable {
  const QuotationEvent();
  @override
  List<Object?> get props => [];
}

class LoadQuotations extends QuotationEvent {}

class AddQuotation extends QuotationEvent {
  final QuotationEntity quotation;
  const AddQuotation(this.quotation);
  @override
  List<Object?> get props => [quotation];
}

class UpdateQuotation extends QuotationEvent {
  final QuotationEntity quotation;
  const UpdateQuotation(this.quotation);
  @override
  List<Object?> get props => [quotation];
}

class DeleteQuotation extends QuotationEvent {
  final String quotationId;
  const DeleteQuotation(this.quotationId);
  @override
  List<Object?> get props => [quotationId];
}
