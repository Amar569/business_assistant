import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/domain/repositories/customer_repository_interface.dart';

class AddCustomerUseCase {
  final CustomerRepositoryInterface repository;

  AddCustomerUseCase(this.repository);

  Future<void> execute(CustomerEntity customer) {
    return repository.addCustomer(customer);
  }
}
