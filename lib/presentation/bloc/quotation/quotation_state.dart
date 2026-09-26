import 'package:equatable/equatable.dart';
import 'package:business_assistant/domain/entities/quotation_entity.dart';

abstract class QuotationState extends Equatable {
  const QuotationState();
  @override
  List<Object?> get props => [];
}

class QuotationInitial extends QuotationState {}

class QuotationLoading extends QuotationState {}

class QuotationLoaded extends QuotationState {
  final List<QuotationEntity> quotations;
  const QuotationLoaded(this.quotations);
  @override
  List<Object?> get props => [quotations];
}

class QuotationOperationSuccess extends QuotationState {
  final String message;
  const QuotationOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class QuotationError extends QuotationState {
  final String message;
  const QuotationError(this.message);
  @override
  List<Object?> get props => [message];
}
