import 'package:business_assistant/domain/entities/invoice_entity.dart';

abstract class InvoiceRepositoryInterface {
  /// Get all invoices
  Future<List<InvoiceEntity>> getInvoices();

  /// Get an invoice by ID
  Future<InvoiceEntity?> getInvoiceById(String id);

  /// Get invoices by customer ID
  Future<List<InvoiceEntity>> getInvoicesByCustomer(String customerId);

  /// Get invoices by status
  Future<List<InvoiceEntity>> getInvoicesByStatus(String status);

  /// Add a new invoice
  Future<void> addInvoice(InvoiceEntity invoice);

  /// Update an existing invoice
  Future<void> updateInvoice(InvoiceEntity invoice);

  /// Delete an invoice
  Future<void> deleteInvoice(String id);
}
