import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'environment.dart';

final appConfigProvider = Provider<AppConfig>((_) =>
    throw UnimplementedError('AppConfig must be overridden during bootstrap.'));

final apiBaseUrlProvider =
    StateProvider<String>((ref) => ref.watch(appConfigProvider).apiBaseUrl);

class AppConfig {
  const AppConfig(
      {required this.appName,
      required this.environment,
      required this.apiBaseUrl,
      required this.enableNetworkLogging,
      required this.enableDevelopmentIdentity,
      required this.developmentUserId,
      required this.timeout,
      required this.enableMockMode,
      required this.enableDiagnostics});
  final String appName;
  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool enableNetworkLogging;
  final bool enableDevelopmentIdentity;
  final String developmentUserId;
  final Duration timeout;
  final bool enableMockMode;
  final bool enableDiagnostics;
  bool get permitsDevelopmentSetup => environment.allowsDevelopmentIdentity;
  factory AppConfig.fromDefines({String? apiBaseUrlOverride}) {
    const environment =
        String.fromEnvironment('APP_ENV', defaultValue: 'development');
    const baseUrl = String.fromEnvironment('API_BASE_URL',
        defaultValue: 'http://10.0.2.2:5241');
    const userId =
        String.fromEnvironment('DEVELOPMENT_USER_ID', defaultValue: '');
    const logging =
        bool.fromEnvironment('ENABLE_NETWORK_LOGGING', defaultValue: true);
    const identity =
        bool.fromEnvironment('ENABLE_DEVELOPMENT_IDENTITY', defaultValue: true);
    const diagnostics =
        bool.fromEnvironment('ENABLE_DIAGNOSTICS', defaultValue: true);
    const mockMode =
        bool.fromEnvironment('ENABLE_MOCK_MODE', defaultValue: false);
    const timeoutSeconds =
        int.fromEnvironment('REQUEST_TIMEOUT_SECONDS', defaultValue: 15);
    final parsedEnvironment = AppEnvironmentX.parse(environment);
    return AppConfig(
        appName: 'NutriLens',
        environment: parsedEnvironment,
        apiBaseUrl: apiBaseUrlOverride?.trim().isNotEmpty == true
            ? apiBaseUrlOverride!.trim()
            : baseUrl,
        enableNetworkLogging: parsedEnvironment.isDevelopment && logging,
        enableDevelopmentIdentity:
            parsedEnvironment.allowsDevelopmentIdentity && identity,
        developmentUserId: userId,
        timeout: const Duration(seconds: timeoutSeconds),
        enableMockMode: mockMode,
        enableDiagnostics: diagnostics);
  }
}
