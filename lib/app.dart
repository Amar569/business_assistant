import 'package:business_assistant/core/di/injection_container.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_event.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_event.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_assistant/core/theme/app_theme.dart';
import 'package:business_assistant/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:business_assistant/presentation/screens/customers/customer_list_screen.dart';
import 'package:business_assistant/presentation/screens/invoices/invoice_list_screen.dart';
import 'package:business_assistant/presentation/screens/payments/payment_list_screen.dart';
import 'package:business_assistant/presentation/screens/settings/settings_screen.dart';
import 'package:business_assistant/presentation/bloc/customer/customer_bloc.dart';
import 'package:business_assistant/presentation/bloc/invoice/invoice_bloc.dart';
import 'package:business_assistant/presentation/bloc/payment/payment_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_bloc.dart';
import 'package:business_assistant/presentation/bloc/quotation/quotation_event.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CustomerBloc>(
          create: (context) =>
              GetIt.instance<CustomerBloc>()..add(LoadCustomers()),
        ),
        BlocProvider<InvoiceBloc>(
          create: (context) =>
              GetIt.instance<InvoiceBloc>()..add(LoadInvoices()),
        ),
        BlocProvider<PaymentBloc>(
          create: (context) =>
              GetIt.instance<PaymentBloc>()..add(LoadPayments()),
        ),
        BlocProvider(
            create: (context) =>
                GetIt.instance<QuotationBloc>()..add(LoadQuotations())),
        BlocProvider(create: (_) => getIt<PaymentBloc>()..add(LoadPayments())),
      ],
      child: MaterialApp(
        title: 'Business Manager',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const DashboardScreen(),
      ),
    );
  }
}
