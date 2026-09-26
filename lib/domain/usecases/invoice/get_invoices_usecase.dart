import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:business_assistant/domain/repositories/invoice_repository_interface.dart';

class GetInvoicesUseCase {
  final InvoiceRepositoryInterface repository;

  GetInvoicesUseCase(this.repository);

  Future<List<InvoiceEntity>> execute() {
    return repository.getInvoices();
  }
}
