import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../app/config/app_config.dart';
import '../../../core/networking/api_client.dart';
import '../data/meal_vision_settings_repository.dart';

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
                  'Privacy controls will expand with production authentication.'),
              leading: Icon(Icons.privacy_tip_outlined)),
          const ListTile(
              enabled: false,
              title: Text('Log out'),
              subtitle: Text('Available after production authentication.'),
              leading: Icon(Icons.logout)),
        ]));
  }
}
