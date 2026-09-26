import 'package:business_assistant/data/datasources/local/local_datasource.dart';
import 'package:business_assistant/data/models/invoice_model.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:business_assistant/domain/repositories/invoice_repository_interface.dart';
import 'package:business_assistant/data/datasources/local/local_datasource.dart';
import 'package:business_assistant/domain/repositories/payment_repository_interface.dart';

class InvoiceRepositoryImpl implements InvoiceRepositoryInterface {
  final LocalDataSource localDataSource;

  InvoiceRepositoryImpl(this.localDataSource);

  @override
  Future<List<InvoiceEntity>> getInvoices() async {
    final maps =
        await localDataSource.query('invoices', orderBy: 'createdAt DESC');
    return maps.map((map) => InvoiceModel.fromMap(map)).toList();
  }

  @override
  Future<InvoiceEntity?> getInvoiceById(String id) async {
    final maps = await localDataSource.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return InvoiceModel.fromMap(maps.first);
  }

  @override
  Future<List<InvoiceEntity>> getInvoicesByCustomer(String customerId) async {
    final maps = await localDataSource.query(
      'invoices',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => InvoiceModel.fromMap(map)).toList();
  }

  @override
  Future<void> addInvoice(InvoiceEntity invoice) async {
    final model = InvoiceModel.fromEntity(invoice);
    await localDataSource.insert('invoices', model.toMap());
  }

  @override
  Future<void> updateInvoice(InvoiceEntity invoice) async {
    final model = InvoiceModel.fromEntity(invoice);
    await localDataSource.update(
      'invoices',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  @override
  Future<void> deleteInvoice(String id) async {
    await localDataSource.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<InvoiceEntity>> getInvoicesByStatus(String status) async {
    final maps = await localDataSource.query(
      'invoices',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => InvoiceModel.fromMap(map)).toList();
  }
}
