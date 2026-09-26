import 'package:business_assistant/domain/repositories/customer_repository_interface.dart';
import 'package:business_assistant/domain/repositories/invoice_repository_interface.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_event.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_state.dart';
import 'package:business_assistant/domain/usecases/payment/record_payment_usecase.dart';
import 'package:business_assistant/domain/usecases/payment/get_pending_payments_usecase.dart';
import 'package:business_assistant/domain/repositories/payment_repository_interface.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final RecordPaymentUseCase recordPaymentUseCase;
  final GetPendingPaymentsUseCase getPendingPaymentsUseCase;
  final PaymentRepositoryInterface paymentRepository;
  final InvoiceRepositoryInterface invoiceRepository;
  final CustomerRepositoryInterface customerRepository;

  PaymentBloc({
    required this.recordPaymentUseCase,
    required this.getPendingPaymentsUseCase,
    required this.paymentRepository,
    required this.invoiceRepository,
    required this.customerRepository,
  }) : super(PaymentInitial()) {
    on<LoadPayments>(_onLoadPayments);
    on<AddPayment>(_onAddPayment);
    on<UpdatePayment>(_onUpdatePayment);
    on<DeletePayment>(_onDeletePayment);
    on<LoadPendingPayments>(_onLoadPendingPayments);
  }

  Future<void> _onLoadPayments(
    LoadPayments event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final payments = await paymentRepository.getPayments();
      final pendingPayments = await getPendingPaymentsUseCase.execute();
      emit(PaymentLoaded(
        payments: payments,
        pendingPayments: pendingPayments,
      ));
    } catch (e) {
      emit(PaymentError('Failed to load payments: $e'));
    }
  }

  Future<void> _onAddPayment(
    AddPayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      // 1. Save the payment
      await recordPaymentUseCase.execute(event.payment);

      // 2. Sync invoice status + customer outstanding balance
      await _syncInvoiceAndCustomer(event.payment.invoiceId);

      final payments = await paymentRepository.getPayments();
      final pendingPayments = await getPendingPaymentsUseCase.execute();
      emit(PaymentLoaded(
        payments: payments,
        pendingPayments: pendingPayments,
      ));
      emit(PaymentOperationSuccess('Payment recorded successfully'));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onUpdatePayment(
    UpdatePayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      await paymentRepository.updatePayment(event.payment);
      await _syncInvoiceAndCustomer(event.payment.invoiceId);

      final payments = await paymentRepository.getPayments();
      final pendingPayments = await getPendingPaymentsUseCase.execute();
      emit(PaymentLoaded(
        payments: payments,
        pendingPayments: pendingPayments,
      ));
      emit(PaymentOperationSuccess('Payment updated successfully'));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onDeletePayment(
    DeletePayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      // Need the invoiceId before deleting, to re-sync afterward
      final payment = await paymentRepository.getPaymentById(event.paymentId);

      await paymentRepository.deletePayment(event.paymentId);

      if (payment != null) {
        await _syncInvoiceAndCustomer(payment.invoiceId);
      }

      final payments = await paymentRepository.getPayments();
      final pendingPayments = await getPendingPaymentsUseCase.execute();
      emit(PaymentLoaded(
        payments: payments,
        pendingPayments: pendingPayments,
      ));
      emit(PaymentOperationSuccess('Payment deleted successfully'));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onLoadPendingPayments(
    LoadPendingPayments event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      final pendingPayments = await getPendingPaymentsUseCase.execute();
      final payments = await paymentRepository.getPayments();
      emit(PaymentLoaded(
        payments: payments,
        pendingPayments: pendingPayments,
      ));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  /// Recalculates an invoice's paid status based on total payments received,
  /// then recalculates the linked customer's outstanding balance across
  /// all their unpaid invoices.
  Future<void> _syncInvoiceAndCustomer(String invoiceId) async {
    final invoice = await invoiceRepository.getInvoiceById(invoiceId);
    if (invoice == null) return;

    // Sum all "Completed" payments made against this invoice
    final allPayments = await paymentRepository.getPaymentsByInvoice(invoiceId);
    final totalPaid = allPayments
        .where((p) => p.status == 'Completed')
        .fold<double>(0, (sum, p) => sum + p.amount);

    // Determine new status
    String newStatus = invoice.status;
    if (totalPaid >= invoice.total) {
      newStatus = 'Paid';
    } else if (totalPaid > 0 && invoice.status == 'Draft') {
      newStatus = 'Sent'; // partially paid, no longer just a draft
    }

    if (newStatus != invoice.status) {
      final updatedInvoice = InvoiceEntity(
        id: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        customerId: invoice.customerId,
        date: invoice.date,
        dueDate: invoice.dueDate,
        subtotal: invoice.subtotal,
        tax: invoice.tax,
        taxRate: invoice.taxRate,
        total: invoice.total,
        status: newStatus,
        items: invoice.items,
        notes: invoice.notes,
        createdAt: invoice.createdAt,
        updatedAt: DateTime.now(),
      );
      await invoiceRepository.updateInvoice(updatedInvoice);
    }

    // Recalculate the customer's outstanding balance from ALL their
    // non-cancelled, non-paid invoices
    final customer =
        await customerRepository.getCustomerById(invoice.customerId);
    if (customer == null) return;

    final customerInvoices =
        await invoiceRepository.getInvoicesByCustomer(invoice.customerId);

    double outstanding = 0;
    for (final inv in customerInvoices) {
      if (inv.status == 'Paid' || inv.status == 'Cancelled') continue;

      final invPayments = await paymentRepository.getPaymentsByInvoice(inv.id);
      final invPaid = invPayments
          .where((p) => p.status == 'Completed')
          .fold<double>(0, (sum, p) => sum + p.amount);

      outstanding += (inv.total - invPaid).clamp(0, double.infinity);
    }

    final updatedCustomer = CustomerEntity(
      id: customer.id,
      name: customer.name,
      email: customer.email,
      phone: customer.phone,
      address: customer.address,
      gstin: customer.gstin,
      outstandingBalance: outstanding,
      createdAt: customer.createdAt,
      updatedAt: DateTime.now(),
    );
    await customerRepository.updateCustomer(updatedCustomer);
  }
}
