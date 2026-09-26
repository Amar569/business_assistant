import 'package:business_assistant/domain/repositories/customer_repository_interface.dart';

class DeleteCustomerUseCase {
  final CustomerRepositoryInterface repository;

  DeleteCustomerUseCase(this.repository);

  Future<void> execute(String id) {
    return repository.deleteCustomer(id);
  }
}
