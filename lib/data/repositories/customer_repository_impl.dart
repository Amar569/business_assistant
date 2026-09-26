import 'package:business_assistant/data/datasources/local/local_datasource.dart';
import 'package:business_assistant/data/models/customer_model.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/domain/repositories/customer_repository_interface.dart';
import 'package:business_assistant/data/datasources/local/local_datasource.dart';
import 'package:business_assistant/domain/repositories/payment_repository_interface.dart';

class CustomerRepositoryImpl implements CustomerRepositoryInterface {
  final LocalDataSource localDataSource;

  CustomerRepositoryImpl(this.localDataSource);

  @override
  Future<List<CustomerEntity>> getCustomers() async {
    final maps = await localDataSource.query('customers', orderBy: 'name ASC');
    return maps.map((map) => CustomerModel.fromMap(map)).toList();
  }

  @override
  Future<CustomerEntity?> getCustomerById(String id) async {
    final maps = await localDataSource.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CustomerModel.fromMap(maps.first);
  }

  @override
  Future<void> addCustomer(CustomerEntity customer) async {
    final model = CustomerModel.fromEntity(customer);
    await localDataSource.insert('customers', model.toMap());
  }

  @override
  Future<void> updateCustomer(CustomerEntity customer) async {
    final model = CustomerModel.fromEntity(customer);
    await localDataSource.update(
      'customers',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await localDataSource.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<CustomerEntity>> searchCustomers(String query) async {
    final maps = await localDataSource.query(
      'customers',
      where: 'name LIKE ? OR email LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return maps.map((map) => CustomerModel.fromMap(map)).toList();
  }
}
