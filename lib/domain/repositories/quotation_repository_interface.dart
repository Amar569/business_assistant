import 'package:business_assistant/domain/entities/quotation_entity.dart';

abstract class QuotationRepositoryInterface {
  Future<List<QuotationEntity>> getQuotations();
  Future<QuotationEntity?> getQuotationById(String id);
  Future<List<QuotationEntity>> getQuotationsByCustomer(String customerId);
  Future<void> addQuotation(QuotationEntity quotation);
  Future<void> updateQuotation(QuotationEntity quotation);
  Future<void> deleteQuotation(String id);
}
