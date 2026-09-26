import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/domain/repositories/customer_repository_interface.dart';

class GetCustomersUseCase {
  final CustomerRepositoryInterface repository;

  GetCustomersUseCase(this.repository);

  Future<List<CustomerEntity>> execute() {
    return repository.getCustomers();
  }
}
