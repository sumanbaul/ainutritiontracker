import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_config.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/result/result.dart';
import '../domain/health_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});
  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  String _message = 'Connecting to NutriLens…';
  @override
  void initState() {
    super.initState();
    Future.microtask(_route);
  }

  Future<void> _route() async {
    final config = ref.read(appConfigProvider);
    final identity = ref.read(developmentIdentityProvider);
    final health = ApiHealthRepository(ref.read(apiClientProvider));
    final result = await health.checkLiveness();
    if (!mounted) {
      return;
    }
    if (result is Failure<HealthStatus>) {
      setState(() => _message = kDebugMode && result.failure.details != null
          ? '${result.failure.message}\n\n${result.failure.details}'
          : result.failure.message);
      return;
    }
    if (config.permitsDevelopmentSetup &&
        await identity.currentUserId() == null) {
      if (!mounted) {
        return;
      }
      context.go(RoutePaths.setup);
      return;
    }
    final profile = await ref.read(profileRepositoryProvider).get();
    if (!mounted) {
      return;
    }
    context.go(profile is Success<UserProfile?> && profile.value != null
        ? RoutePaths.home
        : RoutePaths.onboarding);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(_message),
        if (!_message.startsWith('Connecting'))
          TextButton(onPressed: _route, child: const Text('Retry'))
      ])));
}
