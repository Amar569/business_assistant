// get_quotations_usecase.dart
import 'package:business_assistant/domain/entities/quotation_entity.dart';
import 'package:business_assistant/domain/repositories/quotation_repository_interface.dart';

class GetQuotationsUseCase {
  final QuotationRepositoryInterface repository;
  GetQuotationsUseCase(this.repository);

  Future<List<QuotationEntity>> call() => repository.getQuotations();
}
