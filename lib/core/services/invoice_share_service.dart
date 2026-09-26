import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';

class InvoiceShareService {
  static String? _sanitizedPhone(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return null;
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    if (digits.length == 10) return '91$digits';
    return digits;
  }

  static String _buildMessage({
    required InvoiceEntity invoice,
    required CustomerEntity customer,
    required String businessName,
  }) {
    final biz = businessName.isNotEmpty ? businessName : 'us';
    return 'Hi ${customer.name},\n\n'
        'Please find attached invoice ${invoice.invoiceNumber} '
        'for Rs${invoice.total.toStringAsFixed(2)}'
        '${invoice.dueDate != null && invoice.dueDate!.isNotEmpty ? ", due on ${invoice.dueDate}" : ""}.\n\n'
        'Thank you for your business!\n$biz';
  }

  static Future<void> shareViaSystemSheet({
    required File pdfFile,
    required InvoiceEntity invoice,
    required CustomerEntity customer,
    required String businessName,
  }) async {
    if (!await pdfFile.exists()) {
      throw Exception('PDF file does not exist at ${pdfFile.path}');
    }

    final fileSize = await pdfFile.length();
    if (fileSize == 0) {
      throw Exception('PDF file is empty (0 bytes)');
    }
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'Invoice ${invoice.invoiceNumber}',
      text: _buildMessage(
        invoice: invoice,
        customer: customer,
        businessName: businessName,
      ),
    );
  }

  static Future<bool> openWhatsAppChat({
    required InvoiceEntity invoice,
    required CustomerEntity customer,
    required String businessName,
  }) async {
    final phone = _sanitizedPhone(customer.phone);
    if (phone == null) return false;

    final message = Uri.encodeComponent(_buildMessage(
      invoice: invoice,
      customer: customer,
      businessName: businessName,
    ));
    final uri = Uri.parse('https://wa.me/$phone?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  static Future<bool> openEmailDraft({
    required InvoiceEntity invoice,
    required CustomerEntity customer,
    required String businessName,
  }) async {
    final email = customer.email?.trim();
    if (email == null || email.isEmpty) return false;

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Invoice ${invoice.invoiceNumber}',
        'body': _buildMessage(
          invoice: invoice,
          customer: customer,
          businessName: businessName,
        ),
      },
    );

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      return launched;
    } catch (e) {
      return false;
    }
  }
}
