import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_tracker_app/app/config/app_config.dart';
import 'package:nutrition_tracker_app/app/config/environment.dart';

void main() {
  test(
      'development configuration enables local identity only outside production',
      () {
    const config = AppConfig(
        appName: 'NutriLens',
        environment: AppEnvironment.development,
        apiBaseUrl: 'http://10.0.2.2:5241',
        enableNetworkLogging: true,
        enableDevelopmentIdentity: true,
        developmentUserId: 'local-user',
        timeout: Duration(seconds: 15),
        enableMockMode: false,
        enableDiagnostics: true);
    expect(config.permitsDevelopmentSetup, isTrue);
  });
}
