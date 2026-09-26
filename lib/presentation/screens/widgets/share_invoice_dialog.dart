import 'dart:io';
import 'package:flutter/material.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:business_assistant/core/services/invoice_share_service.dart';

class ShareInvoiceDialog extends StatelessWidget {
  final File pdfFile;
  final InvoiceEntity invoice;
  final CustomerEntity customer;
  final String businessName;

  const ShareInvoiceDialog({
    super.key,
    required this.pdfFile,
    required this.invoice,
    required this.customer,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone =
        customer.phone != null && customer.phone!.trim().isNotEmpty;
    final hasEmail =
        customer.email != null && customer.email!.trim().isNotEmpty;

    return AlertDialog(
      title: Text('Share Invoice ${invoice.invoiceNumber}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send to ${customer.name}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Primary option — attaches the actual PDF
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.share, color: Colors.white, size: 20),
            ),
            title: const Text('Share PDF'),
            subtitle: const Text(
              'Pick WhatsApp, Email, Drive etc. — PDF attached',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () async {
              Navigator.pop(context);
              try {
                await InvoiceShareService.shareViaSystemSheet(
                  pdfFile: pdfFile,
                  invoice: invoice,
                  customer: customer,
                  businessName: businessName,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not share PDF: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(),

          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: hasPhone,
            leading: CircleAvatar(
              backgroundColor: hasPhone ? Colors.green : Colors.grey,
              child: const Icon(Icons.chat, color: Colors.white, size: 20),
            ),
            title: const Text('WhatsApp message'),
            subtitle: Text(
              hasPhone
                  ? 'Text only — ${customer.phone}'
                  : 'No phone number saved',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: hasPhone
                ? () async {
                    Navigator.pop(context);
                    final ok = await InvoiceShareService.openWhatsAppChat(
                      invoice: invoice,
                      customer: customer,
                      businessName: businessName,
                    );
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open WhatsApp'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                : null,
          ),

          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: hasEmail,
            leading: CircleAvatar(
              backgroundColor: hasEmail ? Colors.orange : Colors.grey,
              child: const Icon(Icons.email, color: Colors.white, size: 20),
            ),
            title: const Text('Email draft'),
            subtitle: Text(
              hasEmail ? 'Text only — ${customer.email}' : 'No email saved',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: hasEmail
                ? () async {
                    Navigator.pop(context);
                    final ok = await InvoiceShareService.openEmailDraft(
                      invoice: invoice,
                      customer: customer,
                      businessName: businessName,
                    );
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open email client'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
      ],
    );
  }
}
