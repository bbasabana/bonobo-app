/// Configuration de l'application — valeurs injectées à la compilation.
///
/// Usage pour le build :
///   flutter run --dart-define=API_BASE_URL=https://bonobo-api.vercel.app
///   flutter build apk --dart-define=API_BASE_URL=https://bonobo-api.vercel.app
///
/// En développement (mode debug), la valeur par défaut est utilisée si
/// --dart-define n'est pas spécifié.
class AppConfig {
  AppConfig._();

  /// URL de base du backend Bonobo.
  /// Injectée via --dart-define=API_BASE_URL=...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bonobo-manage.vercel.app', 
  );

  /// Timeout réseau pour les appels auth (secondes).
  static const int authTimeoutSeconds = 10;

  /// Timeout réseau pour les analytics (secondes).
  static const int analyticsTimeoutSeconds = 8;
}
