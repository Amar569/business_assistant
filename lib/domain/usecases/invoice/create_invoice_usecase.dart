import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:business_assistant/domain/repositories/invoice_repository_interface.dart';

class CreateInvoiceUseCase {
  final InvoiceRepositoryInterface repository;

  CreateInvoiceUseCase(this.repository);

  Future<void> execute(InvoiceEntity invoice) {
    return repository.addInvoice(invoice);
  }
}
