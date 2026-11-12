/// Build-time configuration.
///
/// Override the API host without touching code:
/// `flutter run --dart-define=API_BASE_URL=https://your-host/api/v1`
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://multivendorbackend.vercel.app/api/v1',
  );

  /// Flat delivery charge applied per seller shipment (matches the web store).
  static const shippingPerSeller = 60.0;

  static const currencySymbol = '৳';
}
