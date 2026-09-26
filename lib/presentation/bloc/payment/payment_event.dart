import 'package:equatable/equatable.dart';
import 'package:business_assistant/domain/entities/payment_entity.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class LoadPayments extends PaymentEvent {}

class AddPayment extends PaymentEvent {
  final PaymentEntity payment;

  const AddPayment(this.payment);

  @override
  List<Object?> get props => [payment];
}

class UpdatePayment extends PaymentEvent {
  final PaymentEntity payment;

  const UpdatePayment(this.payment);

  @override
  List<Object?> get props => [payment];
}

class DeletePayment extends PaymentEvent {
  final String paymentId;

  const DeletePayment(this.paymentId);

  @override
  List<Object?> get props => [paymentId];
}

class LoadPendingPayments extends PaymentEvent {}
