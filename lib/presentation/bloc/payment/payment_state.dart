import 'package:equatable/equatable.dart';
import 'package:business_assistant/domain/entities/payment_entity.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentLoaded extends PaymentState {
  final List<PaymentEntity> payments;
  final List<PaymentEntity> pendingPayments;

  const PaymentLoaded({
    required this.payments,
    required this.pendingPayments,
  });

  @override
  List<Object?> get props => [payments, pendingPayments];
}

class PaymentOperationSuccess extends PaymentState {
  final String message;

  const PaymentOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError(this.message);

  @override
  List<Object?> get props => [message];
}
