import 'package:intl/intl.dart';

class Helpers {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatCurrency(double amount) {
    return 'Rs${amount.toStringAsFixed(2)}';
  }

  static String generateInvoiceNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8, 12);
    return 'INV-$year$month$day-$random';
  }

  static String generateQuotationNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8, 12);
    return 'QUOT-$year$month$day-$random';
  }

  static String generatePaymentId() {
    return 'PAY-${DateTime.now().millisecondsSinceEpoch}';
  }

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static double calculateGST(double amount, double rate) {
    return (amount * rate) / 100;
  }

  static double calculateCGST(double amount, double rate) {
    return calculateGST(amount, rate) / 2;
  }

  static double calculateSGST(double amount, double rate) {
    return calculateGST(amount, rate) / 2;
  }

  static String getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  static bool isValidGSTIN(String gstin) {
    return RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$')
        .hasMatch(gstin);
  }
}
