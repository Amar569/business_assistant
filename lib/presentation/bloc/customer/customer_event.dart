import 'package:equatable/equatable.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {}

class AddCustomer extends CustomerEvent {
  final CustomerEntity customer;

  const AddCustomer(this.customer);

  @override
  List<Object?> get props => [customer];
}

class UpdateCustomer extends CustomerEvent {
  final CustomerEntity customer;

  const UpdateCustomer(this.customer);

  @override
  List<Object?> get props => [customer];
}

class DeleteCustomer extends CustomerEvent {
  final String customerId;

  const DeleteCustomer(this.customerId);

  @override
  List<Object?> get props => [customerId];
}

class SearchCustomers extends CustomerEvent {
  final String query;

  const SearchCustomers(this.query);

  @override
  List<Object?> get props => [query];
}
