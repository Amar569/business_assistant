import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:business_assistant/core/utils/pdf_generator.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/domain/entities/quotation_entity.dart';

class PdfStorageService {
  Future<File> generateAndSaveInvoicePdf({
    required InvoiceEntity invoice,
    required CustomerEntity customer,
    required Map<String, dynamic> businessInfo,
  }) async {
    final Uint8List bytes = await PdfGenerator.generateInvoicePdf(
      invoice: invoice,
      customer: customer,
      businessInfo: businessInfo,
    );

    final directory = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${directory.path}/documents');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }

    final file = File('${docsDir.path}/Invoice_${invoice.invoiceNumber}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<File> generateAndSaveQuotationPdf({
    required QuotationEntity quotation,
    required CustomerEntity customer,
    required Map<String, dynamic> businessInfo,
  }) async {
    final Uint8List bytes = await PdfGenerator.generateQuotationPdf(
      quotation: quotation,
      customer: customer,
      businessInfo: businessInfo,
    );

    final directory = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${directory.path}/documents');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }

    final file =
        File('${docsDir.path}/Quotation_${quotation.quotationNumber}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

}
