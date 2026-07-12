import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../app/config/app_config.dart';
import '../../../core/networking/api_client.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
