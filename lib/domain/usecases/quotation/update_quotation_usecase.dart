// update_quotation_usecase.dart
import 'package:business_assistant/domain/entities/quotation_entity.dart';
import 'package:business_assistant/domain/repositories/quotation_repository_interface.dart';

class UpdateQuotationUseCase {
  final QuotationRepositoryInterface repository;
  UpdateQuotationUseCase(this.repository);

  Future<void> call(QuotationEntity quotation) =>
      repository.updateQuotation(quotation);
}
