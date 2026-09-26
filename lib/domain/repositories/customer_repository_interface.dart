import 'package:business_assistant/domain/entities/customer_entity.dart';

abstract class CustomerRepositoryInterface {
  /// Get all customers
  Future<List<CustomerEntity>> getCustomers();

  /// Get a customer by ID
  Future<CustomerEntity?> getCustomerById(String id);

  /// Add a new customer
  Future<void> addCustomer(CustomerEntity customer);

  /// Update an existing customer
  Future<void> updateCustomer(CustomerEntity customer);

  /// Delete a customer
  Future<void> deleteCustomer(String id);

  /// Search customers by name, email, or phone
  Future<List<CustomerEntity>> searchCustomers(String query);
}
