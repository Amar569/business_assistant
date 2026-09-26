import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_assistant/data/datasources/local/local_datasource.dart';
import 'package:business_assistant/data/repositories/customer_repository_impl.dart';
import 'package:business_assistant/data/repositories/invoice_repository_impl.dart';
import 'package:business_assistant/data/repositories/payment_repository_impl.dart';
import 'package:business_assistant/domain/repositories/customer_repository_interface.dart';
import 'package:business_assistant/domain/repositories/invoice_repository_interface.dart';
import 'package:business_assistant/domain/repositories/payment_repository_interface.dart';
import 'package:business_assistant/domain/usecases/customer/add_customer_usecase.dart';
import 'package:business_assistant/domain/usecases/customer/get_customers_usecase.dart';
import 'package:business_assistant/domain/usecases/customer/update_customer_usecase.dart';
import 'package:business_assistant/domain/usecases/customer/delete_customer_usecase.dart';
import 'package:business_assistant/domain/usecases/invoice/create_invoice_usecase.dart';
import 'package:business_assistant/domain/usecases/invoice/get_invoices_usecase.dart';
import 'package:business_assistant/domain/usecases/invoice/update_invoice_usecase.dart';
import 'package:business_assistant/domain/usecases/payment/record_payment_usecase.dart';
import 'package:business_assistant/domain/usecases/payment/get_pending_payments_usecase.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_bloc.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_bloc.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_bloc.dart';
import 'package:business_assistant/data/repositories/quotation_repository_impl.dart';
import 'package:business_assistant/domain/repositories/quotation_repository_interface.dart';
import 'package:business_assistant/domain/usecases/quotation/get_quotations_usecase.dart';
import 'package:business_assistant/domain/usecases/quotation/add_quotation_usecase.dart';
import 'package:business_assistant/domain/usecases/quotation/update_quotation_usecase.dart';
import 'package:business_assistant/domain/usecases/quotation/delete_quotation_usecase.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_bloc.dart';
import 'package:business_assistant/data/services/backup_service.dart';
import 'package:business_assistant/data/services/pdf_storage_service.dart';
import 'package:business_assistant/domain/usecases/invoice/delete_invoice_usecase.dart';


final GetIt getIt = GetIt.instance;

Future<void> initDependencyInjection() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);

  // Datasources
  getIt.registerLazySingleton<LocalDataSource>(() => LocalDataSource());

  // Repositories
  getIt.registerLazySingleton<CustomerRepositoryInterface>(
    () => CustomerRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<InvoiceRepositoryInterface>(
    () => InvoiceRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<PaymentRepositoryInterface>(
    () => PaymentRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<QuotationRepositoryInterface>(
    () => QuotationRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton(() => BackupService(getIt()));

  getIt.registerLazySingleton(() => PdfStorageService());

  // Use Cases - Customer
  getIt.registerLazySingleton(() => GetCustomersUseCase(getIt()));
  getIt.registerLazySingleton(() => AddCustomerUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateCustomerUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteCustomerUseCase(getIt()));

  // Use Cases - Invoice
  getIt.registerLazySingleton(() => GetInvoicesUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateInvoiceUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateInvoiceUseCase(getIt()));

  // Use Cases - Payment
  getIt.registerLazySingleton(() => RecordPaymentUseCase(getIt()));
  getIt.registerLazySingleton(() => GetPendingPaymentsUseCase(getIt()));

  // Use Cases - Quotation
  getIt.registerLazySingleton(() => GetQuotationsUseCase(getIt()));
  getIt.registerLazySingleton(() => AddQuotationUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateQuotationUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteQuotationUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteInvoiceUseCase(getIt()));

  // BLoCs
  getIt.registerFactory(() => CustomerBloc(
        getCustomersUseCase: getIt(),
        addCustomerUseCase: getIt(),
        updateCustomerUseCase: getIt(),
        deleteCustomerUseCase: getIt(),
      ));

  getIt.registerFactory(() => InvoiceBloc(
        getInvoicesUseCase: getIt(),
        createInvoiceUseCase: getIt(),
        updateInvoiceUseCase: getIt(),
        deleteInvoiceUseCase: getIt(),
      ));

  getIt.registerFactory(() => PaymentBloc(
        recordPaymentUseCase: getIt(),
        getPendingPaymentsUseCase: getIt(),
        paymentRepository: getIt(),
        invoiceRepository: getIt(),
        customerRepository: getIt(),
      ));

  // BLoC
  getIt.registerFactory(() => QuotationBloc(
        getQuotationsUseCase: getIt(),
        addQuotationUseCase: getIt(),
        updateQuotationUseCase: getIt(),
        deleteQuotationUseCase: getIt(),
      ));
}
