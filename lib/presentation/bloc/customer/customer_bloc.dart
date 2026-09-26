import 'package:business_assistant/domain/entities/customer_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_event.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_state.dart';
import 'package:business_assistant/domain/usecases/customer/add_customer_usecase.dart';
import 'package:business_assistant/domain/usecases/customer/get_customers_usecase.dart';
import 'package:business_assistant/domain/usecases/customer/update_customer_usecase.dart';
import 'package:business_assistant/domain/usecases/customer/delete_customer_usecase.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final GetCustomersUseCase getCustomersUseCase;
  final AddCustomerUseCase addCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final DeleteCustomerUseCase deleteCustomerUseCase;

  List<CustomerEntity> allCustomers = [];

  CustomerBloc({
    required this.getCustomersUseCase,
    required this.addCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deleteCustomerUseCase,
  }) : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<AddCustomer>(_onAddCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
    on<SearchCustomers>(_onSearchCustomers);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    try {
      final customers = await getCustomersUseCase.execute();
      allCustomers = customers;
      emit(CustomerLoaded(
        customers: customers,
        filteredCustomers: customers,
      ));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onAddCustomer(
    AddCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await addCustomerUseCase.execute(event.customer);
      final customers = await getCustomersUseCase.execute();
      allCustomers = customers;
      emit(CustomerLoaded(
        customers: customers,
        filteredCustomers: customers,
      ));
      emit(const CustomerOperationSuccess('Customer added successfully'));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await updateCustomerUseCase.execute(event.customer);
      final customers = await getCustomersUseCase.execute();
      allCustomers = customers;
      emit(CustomerLoaded(
        customers: customers,
        filteredCustomers: customers,
      ));
      emit(const CustomerOperationSuccess('Customer updated successfully'));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await deleteCustomerUseCase.execute(event.customerId);
      final customers = await getCustomersUseCase.execute();
      allCustomers = customers;
      emit(CustomerLoaded(
        customers: customers,
        filteredCustomers: customers,
      ));
      emit(const CustomerOperationSuccess('Customer deleted successfully'));
    } catch (e) {
      emit(CustomerError(e.toString()));
    }
  }

  void _onSearchCustomers(
    SearchCustomers event,
    Emitter<CustomerState> emit,
  ) {
    if (state is CustomerLoaded) {
      final currentState = state as CustomerLoaded;
      final filtered = allCustomers.where((customer) {
        return customer.name
                .toLowerCase()
                .contains(event.query.toLowerCase()) ||
            (customer.email
                    ?.toLowerCase()
                    .contains(event.query.toLowerCase()) ??
                false) ||
            (customer.phone?.contains(event.query) ?? false);
      }).toList();

      emit(CustomerLoaded(
        customers: currentState.customers,
        filteredCustomers: filtered,
      ));
    }
  }
}
