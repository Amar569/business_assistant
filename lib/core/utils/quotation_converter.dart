import 'package:business_assistant/core/utils/helpers.dart';
import 'package:business_assistant/domain/entities/quotation_entity.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';

class QuotationConverter {
  /// Builds a new InvoiceEntity from an accepted quotation.
  /// Does NOT save it — caller is responsible for dispatching AddInvoice.
  static InvoiceEntity toInvoice(QuotationEntity quotation) {
    final invoiceItems = quotation.items
        .map((item) => InvoiceItemEntity(
              id: Helpers.generateId(),
              description: item.description,
              quantity: item.quantity,
              rate: item.rate,
              amount: item.amount,
            ))
        .toList();

    return InvoiceEntity(
      id: Helpers.generateId(),
      invoiceNumber: Helpers.generateInvoiceNumber(),
      customerId: quotation.customerId,
      date: Helpers.formatDate(DateTime.now()),
      dueDate: Helpers.formatDate(DateTime.now().add(const Duration(days: 15))),
      subtotal: quotation.subtotal,
      tax: quotation.tax,
      taxRate: quotation.taxRate,
      total: quotation.total,
      status: 'Draft',
      items: invoiceItems,
      notes: quotation.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
