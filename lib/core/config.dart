/// Build-time configuration. Override with `--dart-define=KEY=value`.
class AppConfig {
  const AppConfig._();

  static const appName = 'NaijaMart';

  /// Base URL of the NaijaMart API.
  /// Android emulator: `--dart-define=API_BASE_URL=http://10.0.2.2:8000`
  /// Production: always use an https URL.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const supportPhone =
      String.fromEnvironment('SUPPORT_PHONE', defaultValue: '');
  static const supportWhatsApp =
      String.fromEnvironment('SUPPORT_WHATSAPP', defaultValue: '');
  static const supportEmail =
      String.fromEnvironment('SUPPORT_EMAIL', defaultValue: '');

  /// Shown to customers who choose bank transfer. Leave empty to tell them
  /// to contact support for account details instead.
  static const bankName = String.fromEnvironment('BANK_NAME', defaultValue: '');
  static const bankAccountNumber =
      String.fromEnvironment('BANK_ACCOUNT_NUMBER', defaultValue: '');
  static const bankAccountName =
      String.fromEnvironment('BANK_ACCOUNT_NAME', defaultValue: '');
  static bool get hasBankDetails =>
      bankName.isNotEmpty && bankAccountNumber.isNotEmpty;

  /// Optional public policy URLs. When empty, the in-app policy pages are used.
  static const privacyUrl =
      String.fromEnvironment('PRIVACY_URL', defaultValue: '');
  static const termsUrl = String.fromEnvironment('TERMS_URL', defaultValue: '');

  /// Serves built-in sample products instead of calling the API.
  /// Only for demos and UI work: `--dart-define=USE_DEMO_DATA=true`.
  static const useDemoData =
      bool.fromEnvironment('USE_DEMO_DATA', defaultValue: false);

  static const pageSize = 20;

  /// Categories shared by the storefront filters and the admin product form,
  /// so the two can never drift apart.
  static const categories = <String>[
    'Fashion',
    'Electronics',
    'Home & Living',
    'Beauty',
    'Health',
    'Sports',
    'Food',
    'Accessories',
    'Other',
  ];

  static bool get isSecureApi => apiBaseUrl.startsWith('https://');
}
