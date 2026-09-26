import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_assistant/domain/usecases/quotation/get_quotations_usecase.dart';
import 'package:business_assistant/domain/usecases/quotation/add_quotation_usecase.dart';
import 'package:business_assistant/domain/usecases/quotation/update_quotation_usecase.dart';
import 'package:business_assistant/domain/usecases/quotation/delete_quotation_usecase.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_event.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_state.dart';

class QuotationBloc extends Bloc<QuotationEvent, QuotationState> {
  final GetQuotationsUseCase getQuotationsUseCase;
  final AddQuotationUseCase addQuotationUseCase;
  final UpdateQuotationUseCase updateQuotationUseCase;
  final DeleteQuotationUseCase deleteQuotationUseCase;

  QuotationBloc({
    required this.getQuotationsUseCase,
    required this.addQuotationUseCase,
    required this.updateQuotationUseCase,
    required this.deleteQuotationUseCase,
  }) : super(QuotationInitial()) {
    on<LoadQuotations>(_onLoadQuotations);
    on<AddQuotation>(_onAddQuotation);
    on<UpdateQuotation>(_onUpdateQuotation);
    on<DeleteQuotation>(_onDeleteQuotation);
  }

  Future<void> _onLoadQuotations(
      LoadQuotations event, Emitter<QuotationState> emit) async {
    emit(QuotationLoading());
    try {
      final quotations = await getQuotationsUseCase();
      emit(QuotationLoaded(quotations));
    } catch (e) {
      emit(QuotationError('Failed to load quotations: $e'));
    }
  }

  Future<void> _onAddQuotation(
      AddQuotation event, Emitter<QuotationState> emit) async {
    try {
      await addQuotationUseCase(event.quotation);
      emit(const QuotationOperationSuccess('Quotation created successfully'));
      final quotations = await getQuotationsUseCase();
      emit(QuotationLoaded(quotations));
    } catch (e) {
      emit(QuotationError('Failed to save quotation: $e'));
    }
  }

  Future<void> _onUpdateQuotation(
      UpdateQuotation event, Emitter<QuotationState> emit) async {
    try {
      await updateQuotationUseCase(event.quotation);
      emit(const QuotationOperationSuccess('Quotation updated successfully'));
      final quotations = await getQuotationsUseCase();
      emit(QuotationLoaded(quotations));
    } catch (e) {
      emit(QuotationError('Failed to update quotation: $e'));
    }
  }

  Future<void> _onDeleteQuotation(
      DeleteQuotation event, Emitter<QuotationState> emit) async {
    try {
      await deleteQuotationUseCase(event.quotationId);
      emit(const QuotationOperationSuccess('Quotation deleted successfully'));
      final quotations = await getQuotationsUseCase();
      emit(QuotationLoaded(quotations));
    } catch (e) {
      emit(QuotationError('Failed to delete quotation: $e'));
    }
  }
}
