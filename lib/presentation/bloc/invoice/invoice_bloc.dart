import 'package:intl/intl.dart';
import 'package:business_assistant/domain/entities/invoice_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_event.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_state.dart';
import 'package:business_assistant/domain/usecases/invoice/create_invoice_usecase.dart';
import 'package:business_assistant/domain/usecases/invoice/get_invoices_usecase.dart';
import 'package:business_assistant/domain/usecases/invoice/update_invoice_usecase.dart';
import 'package:business_assistant/domain/usecases/invoice/delete_invoice_usecase.dart';

class InvoiceBloc extends Bloc<InvoiceEvent, InvoiceState> {
  final GetInvoicesUseCase getInvoicesUseCase;
  final CreateInvoiceUseCase createInvoiceUseCase;
  final UpdateInvoiceUseCase updateInvoiceUseCase;
  final DeleteInvoiceUseCase deleteInvoiceUseCase;

  List<InvoiceEntity> allInvoices = [];

  InvoiceBloc({
    required this.getInvoicesUseCase,
    required this.createInvoiceUseCase,
    required this.updateInvoiceUseCase,
    required this.deleteInvoiceUseCase,
  }) : super(InvoiceInitial()) {
    on<LoadInvoices>(_onLoadInvoices);
    on<AddInvoice>(_onAddInvoice);
    on<UpdateInvoice>(_onUpdateInvoice);
    on<DeleteInvoice>(_onDeleteInvoice);
    on<FilterInvoicesByStatus>(_onFilterInvoicesByStatus);
  }

  Future<List<InvoiceEntity>> _applyOverdueStatus(
      List<InvoiceEntity> invoices) async {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final List<InvoiceEntity> result = [];

    for (final invoice in invoices) {
      if (invoice.status == 'Sent' &&
          invoice.dueDate != null &&
          invoice.dueDate!.isNotEmpty) {
        DateTime? dueDate;
        try {
          dueDate = dateFormat.parse(invoice.dueDate!);
        } catch (_) {
          dueDate = null;
        }

        if (dueDate != null && dueDate.isBefore(now)) {
          final overdueInvoice = InvoiceEntity(
            id: invoice.id,
            invoiceNumber: invoice.invoiceNumber,
            customerId: invoice.customerId,
            date: invoice.date,
            dueDate: invoice.dueDate,
            subtotal: invoice.subtotal,
            tax: invoice.tax,
            taxRate: invoice.taxRate,
            total: invoice.total,
            status: 'Overdue',
            items: invoice.items,
            notes: invoice.notes,
            createdAt: invoice.createdAt,
            updatedAt: DateTime.now(),
          );
          await updateInvoiceUseCase.execute(overdueInvoice);
          result.add(overdueInvoice);
          continue;
        }
      }
      result.add(invoice);
    }

    return result;
  }

  Future<void> _onLoadInvoices(
    LoadInvoices event,
    Emitter<InvoiceState> emit,
  ) async {
    emit(InvoiceLoading());
    try {
      final invoices = await getInvoicesUseCase.execute();
      final updatedInvoices = await _applyOverdueStatus(invoices);
      allInvoices = updatedInvoices;
      emit(InvoiceLoaded(
        invoices: updatedInvoices,
        filteredInvoices: updatedInvoices,
      ));
    } catch (e) {
      emit(InvoiceError(e.toString()));
    }
  }

  Future<void> _onAddInvoice(
    AddInvoice event,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      await createInvoiceUseCase.execute(event.invoice);
      final invoices = await getInvoicesUseCase.execute();
      final updatedInvoices = await _applyOverdueStatus(invoices);
      allInvoices = updatedInvoices;
      emit(InvoiceLoaded(
        invoices: updatedInvoices,
        filteredInvoices: updatedInvoices,
      ));
      emit(InvoiceOperationSuccess('Invoice created successfully'));
    } catch (e) {
      emit(InvoiceError(e.toString()));
    }
  }

  Future<void> _onUpdateInvoice(
    UpdateInvoice event,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      await updateInvoiceUseCase.execute(event.invoice);
      final invoices = await getInvoicesUseCase.execute();
      final updatedInvoices = await _applyOverdueStatus(invoices);
      allInvoices = updatedInvoices;
      emit(InvoiceLoaded(
        invoices: updatedInvoices,
        filteredInvoices: updatedInvoices,
      ));
      emit(InvoiceOperationSuccess('Invoice updated successfully'));
    } catch (e) {
      emit(InvoiceError(e.toString()));
    }
  }

  Future<void> _onDeleteInvoice(
    DeleteInvoice event,
    Emitter<InvoiceState> emit,
  ) async {
    try {
      await deleteInvoiceUseCase.execute(event.invoiceId);
      final invoices = await getInvoicesUseCase.execute();
      final updatedInvoices = await _applyOverdueStatus(invoices);
      allInvoices = updatedInvoices;
      emit(InvoiceLoaded(
        invoices: updatedInvoices,
        filteredInvoices: updatedInvoices,
      ));
      emit(InvoiceOperationSuccess('Invoice deleted successfully'));
    } catch (e) {
      emit(InvoiceError(e.toString()));
    }
  }

  void _onFilterInvoicesByStatus(
    FilterInvoicesByStatus event,
    Emitter<InvoiceState> emit,
  ) {
    if (state is InvoiceLoaded) {
      final currentState = state as InvoiceLoaded;
      if (event.status.isEmpty) {
        emit(InvoiceLoaded(
          invoices: currentState.invoices,
          filteredInvoices: allInvoices,
          currentFilter: null,
        ));
        return;
      }
      final filtered = allInvoices.where((invoice) {
        return invoice.status == event.status;
      }).toList();

      emit(InvoiceLoaded(
        invoices: currentState.invoices,
        filteredInvoices: filtered,
        currentFilter: event.status,
      ));
    }
  }
}
