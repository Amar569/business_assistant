import 'package:business_assistant/domain/repositories/invoice_repository_interface.dart';

class DeleteInvoiceUseCase {
  final InvoiceRepositoryInterface repository;
  DeleteInvoiceUseCase(this.repository);

  Future<void> execute(String id) => repository.deleteInvoice(id);
}
