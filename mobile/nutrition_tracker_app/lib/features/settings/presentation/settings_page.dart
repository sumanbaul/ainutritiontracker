import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../app/config/app_config.dart';
import '../../../core/networking/api_client.dart';
import '../data/meal_vision_settings_repository.dart';
import '../../auth/data/auth_service.dart';
import '../../../core/storage/local_database.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_paths.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late Future<List<MealVisionCapability>> _capabilities;
  @override
  void initState() {
    super.initState();
    _capabilities =
        ref.read(mealVisionSettingsRepositoryProvider).capabilities();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    final config = ref.watch(appConfigProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('Appearance')),
          for (final value in ThemeMode.values)
            RadioListTile<ThemeMode>(
                title:
                    Text(value.name[0].toUpperCase() + value.name.substring(1)),
                value: value,
                groupValue: mode,
                onChanged: (selected) {
                  if (selected != null) {
                    ref.read(themeModeProvider.notifier).set(selected);
                  }
                }),
          const Divider(),
          ListTile(
              title: const Text('Backend status'),
              subtitle: Text(config.apiBaseUrl),
              leading: const Icon(Icons.cloud_outlined)),
          if (config.permitsDevelopmentSetup)
            ListTile(
                title: const Text('Development controls'),
                subtitle: Text(
                    '${config.environment.name} • identity ${config.enableDevelopmentIdentity ? 'enabled' : 'disabled'}'),
                leading: const Icon(Icons.developer_mode)),
          if (config.permitsDevelopmentSetup)
            FutureBuilder<List<MealVisionCapability>>(
                future: _capabilities,
                builder: (context, snapshot) => ExpansionTile(
                    leading: const Icon(Icons.auto_awesome_outlined),
                    title: const Text('AI Analysis'),
                    subtitle: const Text(
                        'Development-device preference. Keys remain on the server.'),
                    children: snapshot.hasError
                        ? [
                            const ListTile(
                                title: Text(
                                    'Provider catalog is unavailable. Start the Development API.'))
                          ]
                        : (snapshot.data ?? [])
                            .map((provider) => ListTile(
                                enabled: provider.isAvailable,
                                title: Text(provider.displayName),
                                subtitle: Text(provider.isAvailable
                                    ? '${provider.isLocal ? 'Local: no per-image cloud API cost' : 'Cloud: server-managed credentials'} • ${provider.models.map((m) => m.displayName).join(', ')}'
                                    : provider.unavailableReason ??
                                        'Unavailable'),
                                trailing: provider.isAvailable
                                    ? const Icon(Icons.chevron_right)
                                    : const Icon(Icons.lock_outline),
                                onTap: !provider.isAvailable ||
                                        provider.models.isEmpty
                                    ? null
                                    : () async {
                                        final selected = provider.models
                                            .firstWhere((m) => m.isDefault,
                                                orElse: () =>
                                                    provider.models.first);
                                        await ref
                                            .read(
                                                mealVisionSettingsRepositoryProvider)
                                            .save(MealVisionSelection(
                                                provider.id, selected.id));
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      '${provider.displayName} selected for this development identity.')));
                                        }
                                      }))
                            .toList())),
          ListTile(
              title: const Text('Clear local secure settings'),
              subtitle: const Text(
                  'Removes development identity and theme preference'),
              leading: const Icon(Icons.delete_outline),
              onTap: () async {
                await ref
                    .read(secureStorageProvider)
                    .delete('nutrilens.development.user_id');
                await ref
                    .read(secureStorageProvider)
                    .delete('nutrilens.theme_mode');
              }),
          const ListTile(
              title: Text('About NutriLens'),
              subtitle: Text('Personal nutrition operating system • Phase 9'),
              leading: Icon(Icons.info_outline)),
          const ListTile(
              title: Text('Privacy'),
              subtitle: Text(
                  'AI estimates are informational. Images are private and retained according to server policy.'),
              leading: Icon(Icons.privacy_tip_outlined)),
          if (!config.permitsDevelopmentSetup)
            ListTile(
                title: const Text('Export my data'),
                leading: const Icon(Icons.download_outlined),
                onTap: () async {
                  try {
                    await ref
                        .read(apiClientProvider)
                        .get('/api/account/export');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Your data export was prepared successfully.')));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data export failed.')));
                    }
                  }
                }),
          if (!config.permitsDevelopmentSetup)
            ListTile(
                title: const Text('Delete account'),
                subtitle: const Text(
                    'Permanently removes account data and retained images.'),
                leading: Icon(Icons.delete_forever,
                    color: Theme.of(context).colorScheme.error),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                                  title: const Text('Delete account?'),
                                  content: const Text('This cannot be undone.'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel')),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete permanently'))
                                  ])) ??
                      false;
                  if (!confirmed) return;
                  final auth = ref.read(authServiceProvider);
                  final user = await auth.userId();
                  await ref.read(apiClientProvider).delete('/api/account');
                  if (user != null) {
                    await ref.read(localDatabaseProvider).clearUserData(user);
                  }
                  await auth.clear();
                  if (context.mounted) context.go(RoutePaths.signIn);
                }),
          if (!config.permitsDevelopmentSetup)
            ListTile(
                title: const Text('Log out'),
                subtitle: const Text(
                    'Secure tokens and user-scoped queued changes are cleared.'),
                leading: const Icon(Icons.logout),
                onTap: () async {
                  final auth = ref.read(authServiceProvider);
                  final user = await auth.userId();
                  await auth.signOut();
                  if (user != null) {
                    await ref.read(localDatabaseProvider).clearUserData(user);
                  }
                  if (context.mounted) context.go(RoutePaths.signIn);
                }),
        ]));
  }
}
