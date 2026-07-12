enum AppEnvironment { development, staging, production }

extension AppEnvironmentX on AppEnvironment {
  bool get isDevelopment => this == AppEnvironment.development;
  bool get allowsDevelopmentIdentity =>
      this == AppEnvironment.development || this == AppEnvironment.staging;
  static AppEnvironment parse(String value) => switch (value.toLowerCase()) {
        'production' => AppEnvironment.production,
        'staging' => AppEnvironment.staging,
        _ => AppEnvironment.development
      };
}
