import 'package:equatable/equatable.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';

abstract class CustomerState extends Equatable {
  const CustomerState();

  @override
  List<Object?> get props => [];
}

class CustomerInitial extends CustomerState {}

class CustomerLoading extends CustomerState {}

class CustomerLoaded extends CustomerState {
  final List<CustomerEntity> customers;
  final List<CustomerEntity> filteredCustomers;

  const CustomerLoaded({
    required this.customers,
    required this.filteredCustomers,
  });

  @override
  List<Object?> get props => [customers, filteredCustomers];
}

class CustomerOperationSuccess extends CustomerState {
  final String message;

  const CustomerOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CustomerError extends CustomerState {
  final String message;

  const CustomerError(this.message);

  @override
  List<Object?> get props => [message];
}
