// delete_quotation_usecase.dart
import 'package:business_assistant/domain/repositories/quotation_repository_interface.dart';

class DeleteQuotationUseCase {
  final QuotationRepositoryInterface repository;
  DeleteQuotationUseCase(this.repository);

  Future<void> call(String id) => repository.deleteQuotation(id);
}
