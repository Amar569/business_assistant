import 'package:business_assistant/data/datasources/local/local_datasource.dart';
import 'package:business_assistant/data/models/payment_model.dart';
import 'package:business_assistant/domain/entities/payment_entity.dart';
import 'package:business_assistant/domain/repositories/payment_repository_interface.dart';
import 'package:business_assistant/data/datasources/local/local_datasource.dart';
import 'package:business_assistant/domain/repositories/payment_repository_interface.dart';

class PaymentRepositoryImpl implements PaymentRepositoryInterface {
  final LocalDataSource localDataSource;

  PaymentRepositoryImpl(this.localDataSource);

  @override
  Future<List<PaymentEntity>> getPayments() async {
    final maps =
        await localDataSource.query('payments', orderBy: 'paymentDate DESC');
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  @override
  Future<PaymentEntity?> getPaymentById(String id) async {
    final maps = await localDataSource.query(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PaymentModel.fromMap(maps.first);
  }

  @override
  Future<List<PaymentEntity>> getPaymentsByCustomer(String customerId) async {
    final maps = await localDataSource.query(
      'payments',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'paymentDate DESC',
    );
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  @override
  Future<List<PaymentEntity>> getPaymentsByInvoice(String invoiceId) async {
    final maps = await localDataSource.query(
      'payments',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
      orderBy: 'paymentDate DESC',
    );
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }

  @override
  Future<void> addPayment(PaymentEntity payment) async {
    final model = PaymentModel.fromEntity(payment);
    await localDataSource.insert('payments', model.toMap());
  }

  @override
  Future<void> updatePayment(PaymentEntity payment) async {
    final model = PaymentModel.fromEntity(payment);
    await localDataSource.update(
      'payments',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  @override
  Future<void> deletePayment(String id) async {
    await localDataSource.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<PaymentEntity>> getPendingPayments() async {
    final maps = await localDataSource.query(
      'payments',
      where: 'status = ?',
      whereArgs: ['Pending'],
      orderBy: 'paymentDate ASC',
    );
    return maps.map((map) => PaymentModel.fromMap(map)).toList();
  }
}
