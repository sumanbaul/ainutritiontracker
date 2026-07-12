import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_config.dart';
import '../../../app/router/route_paths.dart';
import '../../../core/networking/api_client.dart';
import '../../../core/result/result.dart';
import '../../splash/domain/health_repository.dart';

class DevelopmentSetupPage extends ConsumerStatefulWidget {
  const DevelopmentSetupPage({super.key});
  @override
  ConsumerState<DevelopmentSetupPage> createState() =>
      _DevelopmentSetupPageState();
}

class _DevelopmentSetupPageState extends ConsumerState<DevelopmentSetupPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _url;
  late final TextEditingController _user;
  String _status = '';
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final c = ref.read(appConfigProvider);
    _url = TextEditingController(text: c.apiBaseUrl);
    _user = TextEditingController(text: c.developmentUserId);
  }

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    super.dispose();
  }

  Future<void> _test({required bool continueToApp}) async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _status = 'Checking health and readiness…';
    });
    final health = ApiHealthRepository(ref.read(apiClientProvider));
    final live = await health.checkLiveness();
    final ready = await health.checkReadiness();
    if (!mounted) return;
    final success = live is Success<HealthStatus> &&
        ready is Success<HealthStatus> &&
        live.value.state == HealthState.healthy &&
        ready.value.state == HealthState.healthy;
    setState(() {
      _busy = false;
      _status = success
          ? 'Health and readiness are healthy.'
          : 'Server is unreachable or not ready.';
    });
    if (success && continueToApp) {
      await ref.read(developmentIdentityProvider).saveUserId(_user.text);
      if (mounted) context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    if (!config.permitsDevelopmentSetup) {
      return const Scaffold(
          body: Center(
              child: Text('Development setup is unavailable in production.')));
    }
    return Scaffold(
        appBar: AppBar(title: const Text('Development setup')),
        body: SafeArea(
            child: Form(
                key: _form,
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  Text('Connect NutriLens to your local backend.',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  TextFormField(
                      controller: _url,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                          labelText: 'API base URL',
                          helperText: 'Android emulator: http://10.0.2.2:5241'),
                      validator: (value) {
                        final uri = Uri.tryParse(value?.trim() ?? '');
                        return uri == null ||
                                !uri.hasScheme ||
                                !(uri.isScheme('http') || uri.isScheme('https'))
                            ? 'Enter a valid HTTP or HTTPS URL.'
                            : null;
                      }),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _user,
                      decoration: const InputDecoration(
                          labelText: 'Development user ID'),
                      validator: (value) => value == null ||
                              value.trim().isEmpty ||
                              value.length > 128
                          ? 'Enter a development user ID up to 128 characters.'
                          : null),
                  const SizedBox(height: 12),
                  Text(
                      'Environment: ${config.environment.name}. Development identity: ${config.enableDevelopmentIdentity ? 'active' : 'off'}.'),
                  if (_status.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_status)),
                  const SizedBox(height: 24),
                  OutlinedButton(
                      onPressed:
                          _busy ? null : () => _test(continueToApp: false),
                      child: const Text('Test connection')),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed:
                          _busy ? null : () => _test(continueToApp: true),
                      child: _busy
                          ? const CircularProgressIndicator()
                          : const Text('Save and continue'))
                ]))));
  }
}
