import 'package:business_assistant/domain/entities/payment_entity.dart';

abstract class PaymentRepositoryInterface {
  /// Get all payments
  Future<List<PaymentEntity>> getPayments();

  /// Get a payment by ID
  Future<PaymentEntity?> getPaymentById(String id);

  /// Get payments by customer ID
  Future<List<PaymentEntity>> getPaymentsByCustomer(String customerId);

  /// Get payments by invoice ID
  Future<List<PaymentEntity>> getPaymentsByInvoice(String invoiceId);

  /// Get all pending payments
  Future<List<PaymentEntity>> getPendingPayments();

  /// Add a new payment
  Future<void> addPayment(PaymentEntity payment);

  /// Update an existing payment
  Future<void> updatePayment(PaymentEntity payment);

  /// Delete a payment
  Future<void> deletePayment(String id);
}
