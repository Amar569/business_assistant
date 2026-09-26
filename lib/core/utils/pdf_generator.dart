import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/domain/entities/quotation_entity.dart';
import 'package:printing/printing.dart';

class PdfGenerator {
  static String _orPlaceholder(dynamic value, String placeholder) {
    final str = (value as String?)?.trim();
    return (str == null || str.isEmpty) ? placeholder : str;
  }

  static bool _hasValue(dynamic value) {
    final str = (value as String?)?.trim();
    return str != null && str.isNotEmpty;
  }

  static Future<pw.ThemeData?> _tryLoadUnicodeTheme() async {
    try {
      final regularData =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      final base = pw.Font.ttf(regularData);
      final bold = pw.Font.ttf(boldData);
      return pw.ThemeData.withFont(base: base, bold: bold);
    } catch (e) {
      // ignore: avoid_print
      print('PdfGenerator: Unicode font unavailable, using default font. $e');
      return null;
    }
  }


  // ── INVOICE ────────────────────────────────────────────────

  static Future<Uint8List> generateInvoicePdf({
    required InvoiceEntity invoice,
    required CustomerEntity customer,
    required Map<String, dynamic> businessInfo,
  }) async {
    try {
      final theme = await _tryLoadUnicodeTheme();
      return await _buildInvoicePdf(
        invoice: invoice,
        customer: customer,
        businessInfo: businessInfo,
        theme: theme,
      );
    } catch (e) {
      // Font passed loading but failed during actual glyph rendering
      // (corrupted/invalid TTF) — retry with the default font so PDF
      // generation never fails outright.
      // ignore: avoid_print
      print(
          'PdfGenerator: invoice render with custom font failed, retrying with default. $e');
      return await _buildInvoicePdf(
        invoice: invoice,
        customer: customer,
        businessInfo: businessInfo,
        theme: null,
      );
    }
  }

  static Future<Uint8List> _buildInvoicePdf({
    required InvoiceEntity invoice,
    required CustomerEntity customer,
    required Map<String, dynamic> businessInfo,
    required pw.ThemeData? theme,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _orPlaceholder(businessInfo['name'], 'Business Name'),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _orPlaceholder(
                            businessInfo['address'], 'Business Address'),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      if (_hasValue(businessInfo['gstin']))
                        pw.Text(
                          'GSTIN: ${businessInfo['gstin']}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      if (_hasValue(businessInfo['phone']))
                        pw.Text(
                          'Phone: ${businessInfo['phone']}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      if (_hasValue(businessInfo['email']))
                        pw.Text(
                          'Email: ${businessInfo['email']}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'No: ${invoice.invoiceNumber}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'Date: ${invoice.date}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      if (invoice.dueDate != null)
                        pw.Text(
                          'Due Date: ${invoice.dueDate}',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 20),

              // Customer Details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Bill To:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          customer.name,
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        if (customer.address != null)
                          pw.Text(
                            customer.address!,
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                        if (customer.phone != null)
                          pw.Text(
                            'Phone: ${customer.phone}',
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                        if (customer.email != null)
                          pw.Text(
                            'Email: ${customer.email}',
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                        if (customer.gstin != null)
                          pw.Text(
                            'GSTIN: ${customer.gstin}',
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Invoice Details:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Status: ${invoice.status}',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        pw.Text(
                          'Payment Terms: Due on receipt',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FixedColumnWidth(80),
                  3: const pw.FixedColumnWidth(100),
                  4: const pw.FixedColumnWidth(120),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'S.No',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Description',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Qty',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Rate',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ...invoice.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${index + 1}',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item.description),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${item.quantity}',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Rs${item.rate.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Rs${item.amount.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 150,
                            child: pw.Text(
                              'Subtotal:',
                              style: const pw.TextStyle(fontSize: 14),
                            ),
                          ),
                          pw.Container(
                            width: 100,
                            child: pw.Text(
                              'Rs${invoice.subtotal.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 150,
                            child: pw.Text(
                              'Tax (${invoice.taxRate}%):',
                              style: const pw.TextStyle(fontSize: 14),
                            ),
                          ),
                          pw.Container(
                            width: 100,
                            child: pw.Text(
                              'Rs${invoice.tax.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      pw.Divider(thickness: 1),
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 150,
                            child: pw.Text(
                              'Total:',
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Container(
                            width: 100,
                            child: pw.Text(
                              'Rs${invoice.total.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 20),

              // Notes
              if (invoice.notes != null) ...[
                pw.Text(
                  'Notes:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  invoice.notes!,
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
              ],

              // Bank Details
              if (_hasValue(businessInfo['bankDetails'])) ...[
                pw.Text(
                  'Bank Details:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  businessInfo['bankDetails'],
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
              ],

              // UPI ID
              if (_hasValue(businessInfo['upiId'])) ...[
                pw.Text(
                  'UPI ID: ${businessInfo['upiId']}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
              ],

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── QUOTATION ──────────────────────────────────────────────

  static Future<Uint8List> generateQuotationPdf({
    required QuotationEntity quotation,
    required CustomerEntity customer,
    required Map<String, dynamic> businessInfo,
  }) async {
    try {
      final theme = await _tryLoadUnicodeTheme();
      return await _buildQuotationPdf(
        quotation: quotation,
        customer: customer,
        businessInfo: businessInfo,
        theme: theme,
      );
    } catch (e) {
      // ignore: avoid_print
      print(
          'PdfGenerator: quotation render with custom font failed, retrying with default. $e');
      return await _buildQuotationPdf(
        quotation: quotation,
        customer: customer,
        businessInfo: businessInfo,
        theme: null,
      );
    }
  }

  static Future<Uint8List> _buildQuotationPdf({
    required QuotationEntity quotation,
    required CustomerEntity customer,
    required Map<String, dynamic> businessInfo,
    required pw.ThemeData? theme,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        theme: theme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _orPlaceholder(businessInfo['name'], 'Business Name'),
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        _orPlaceholder(
                            businessInfo['address'], 'Business Address'),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      if (_hasValue(businessInfo['gstin']))
                        pw.Text(
                          'GSTIN: ${businessInfo['gstin']}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      if (_hasValue(businessInfo['phone']))
                        pw.Text(
                          'Phone: ${businessInfo['phone']}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      if (_hasValue(businessInfo['email']))
                        pw.Text(
                          'Email: ${businessInfo['email']}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'QUOTATION',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'No: ${quotation.quotationNumber}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.Text(
                        'Date: ${quotation.date}',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      if (quotation.validUntil != null)
                        pw.Text(
                          'Valid Until: ${quotation.validUntil}',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 20),

              // Customer Details
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Quoted To:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          customer.name,
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        if (customer.address != null)
                          pw.Text(
                            customer.address!,
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                        if (customer.phone != null)
                          pw.Text(
                            'Phone: ${customer.phone}',
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                        if (customer.email != null)
                          pw.Text(
                            'Email: ${customer.email}',
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                        if (customer.gstin != null)
                          pw.Text(
                            'GSTIN: ${customer.gstin}',
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Quotation Details:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Status: ${quotation.status}',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),
                  1: const pw.FlexColumnWidth(),
                  2: const pw.FixedColumnWidth(80),
                  3: const pw.FixedColumnWidth(100),
                  4: const pw.FixedColumnWidth(120),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'S.No',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Description',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Qty',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Rate',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Amount',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  ...quotation.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${index + 1}',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item.description),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${item.quantity}',
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Rs${item.rate.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Rs${item.amount.toStringAsFixed(2)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 20),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 150,
                            child: pw.Text(
                              'Subtotal:',
                              style: const pw.TextStyle(fontSize: 14),
                            ),
                          ),
                          pw.Container(
                            width: 100,
                            child: pw.Text(
                              'Rs${quotation.subtotal.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 150,
                            child: pw.Text(
                              'Tax (${quotation.taxRate}%):',
                              style: const pw.TextStyle(fontSize: 14),
                            ),
                          ),
                          pw.Container(
                            width: 100,
                            child: pw.Text(
                              'Rs${quotation.tax.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      pw.Divider(thickness: 1),
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 150,
                            child: pw.Text(
                              'Total:',
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Container(
                            width: 100,
                            child: pw.Text(
                              'Rs${quotation.total.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 20),

              // Notes
              if (quotation.notes != null) ...[
                pw.Text(
                  'Notes:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  quotation.notes!,
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
              ],

              // Bank Details
              if (_hasValue(businessInfo['bankDetails'])) ...[
                pw.Text(
                  'Bank Details:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  businessInfo['bankDetails'],
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
              ],

              // UPI ID
              if (_hasValue(businessInfo['upiId'])) ...[
                pw.Text(
                  'UPI ID: ${businessInfo['upiId']}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
              ],

              // Footer
              pw.Center(
                child: pw.Text(
                  'This quotation is valid until the date mentioned above.',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
