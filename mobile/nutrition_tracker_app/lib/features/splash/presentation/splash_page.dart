import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/result/result.dart';
import '../../../shared/presentation/glass_surface.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../../auth/data/auth_service.dart';

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
    final userId = config.permitsDevelopmentSetup
        ? await identity.currentUserId()
        : await ref.read(authServiceProvider).userId();
    final hasSession = config.permitsDevelopmentSetup
        ? userId != null
        : await ref.read(authServiceProvider).hasSession();
    if (!hasSession || userId == null) {
      if (mounted) {
        context.go(config.permitsDevelopmentSetup
            ? RoutePaths.setup
            : RoutePaths.signIn);
      }
      return;
    }
    final profiles = ref.read(profileRepositoryProvider);
    final cached = await profiles.getCached(userId);
    if (!mounted) return;
    if (cached != null) {
      unawaited(profiles.get(userId: userId));
      context.go(RoutePaths.home);
      return;
    }
    final profile = await profiles.get(userId: userId);
    if (!mounted) return;
    context.go(profile is Success<UserProfile?> && profile.value != null
        ? RoutePaths.home
        : RoutePaths.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 34, 26, 24),
          child: Column(children: [
            Text('AI Food\nInsights at Your\nFingertips',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 52, height: .9, fontWeight: FontWeight.w400)),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: reduce ? 1 : .72, end: 1),
                duration:
                    reduce ? Duration.zero : const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, value, child) => Transform.scale(
                    scale: value,
                    child: Opacity(opacity: value.clamp(0, 1), child: child)),
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.pink.withOpacity(.24),
                            blurRadius: 48,
                            offset: const Offset(0, 22))
                      ],
                    ),
                    child: const Icon(Icons.restaurant_rounded,
                        size: 118, color: AppColors.ink),
                  ),
                  const Positioned(
                      left: 12,
                      top: 62,
                      child: _IngredientLabel('Fresh greens')),
                  const Positioned(
                      right: 8, bottom: 72, child: _IngredientLabel('Protein')),
                ]),
              ),
            ),
            GlassSurface(
              radius: 30,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(children: [
                const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 14),
                Expanded(child: Text(_message)),
                if (!_message.startsWith('Connecting'))
                  TextButton(onPressed: _route, child: const Text('Retry'))
              ]),
            )
          ]),
        ),
      ),
    );
  }
}

class _IngredientLabel extends StatelessWidget {
  const _IngredientLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 18)
            ]),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w600)),
      );
}
