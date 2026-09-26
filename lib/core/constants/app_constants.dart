class AppConstants {
  static const String appName = 'Business Manager';
  static const String databaseName = 'business_manager.db';
  static const int databaseVersion = 4;

  // Shared Preferences Keys
  static const String prefBusinessName = 'business_name';
  static const String prefGstin = 'gstin';
  static const String prefLogo = 'logo';
  static const String prefUpiId = 'upi_id';
  static const String prefBankDetails = 'bank_details';
  static const String prefBusinessAddress = 'business_address'; // add
  static const String prefBusinessPhone = 'business_phone'; // add
  static const String prefBusinessEmail = 'business_email';

  // Invoice Constants
  static const String invoicePrefix = 'INV';
  static const String quotationPrefix = 'QUOT';
  static const String paymentPrefix = 'PAY';

  // GST Rates
  static const List<double> gstRates = [0, 5, 12, 18, 28];

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Payment Methods
  static const List<String> paymentMethods = [
    'Cash',
    'Bank Transfer',
    'UPI',
    'Cheque',
    'Credit Card',
    'Debit Card'
  ];

  // Invoice Status
  static const List<String> invoiceStatus = [
    'Draft',
    'Sent',
    'Paid',
    'Overdue',
    'Cancelled'
  ];

  // Shared Preferences Keys
  static const String prefInvoiceTheme = 'invoice_theme';
  static const String prefInvoiceSeries = 'invoice_series';
  static const String prefQuotationSeries = 'quotation_series';
}
