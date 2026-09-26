import 'package:business_assistant/data/datasources/local/local_datasource.dart';
import 'package:business_assistant/data/models/quotation_model.dart';
import 'package:business_assistant/domain/entities/quotation_entity.dart';
import 'package:business_assistant/domain/repositories/quotation_repository_interface.dart';

class QuotationRepositoryImpl implements QuotationRepositoryInterface {
  final LocalDataSource localDataSource;

  QuotationRepositoryImpl(this.localDataSource);

  @override
  Future<List<QuotationEntity>> getQuotations() async {
    final maps = await localDataSource.query(
      'quotations',
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => QuotationModel.fromMap(map)).toList();
  }

  @override
  Future<QuotationEntity?> getQuotationById(String id) async {
    final maps = await localDataSource.query(
      'quotations',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return QuotationModel.fromMap(maps.first);
  }

  @override
  Future<List<QuotationEntity>> getQuotationsByCustomer(
      String customerId) async {
    final maps = await localDataSource.query(
      'quotations',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => QuotationModel.fromMap(map)).toList();
  }

  @override
  Future<void> addQuotation(QuotationEntity quotation) async {
    final model = QuotationModel.fromEntity(quotation);
    await localDataSource.insert('quotations', model.toMap());
  }

  @override
  Future<void> updateQuotation(QuotationEntity quotation) async {
    final model = QuotationModel.fromEntity(quotation);
    await localDataSource.update(
      'quotations',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [quotation.id],
    );
  }

  @override
  Future<void> deleteQuotation(String id) async {
    await localDataSource.delete(
      'quotations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
