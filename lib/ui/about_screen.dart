import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'links.dart';

/// App info: data attribution (CC BY 4.0), privacy summary, version, licences.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snap) {
          final version = snap.data?.version;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ListTile(
                title: Text('Weather Z', style: theme.textTheme.titleLarge),
                subtitle: Text(version == null ? '' : 'Version $version'),
              ),
              const _Header('Weather data'),
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('Weather data by Open-Meteo.com'),
                subtitle: const Text('Forecasts and city search come from the Open-Meteo API.'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => openLink(context, Links.openMeteo),
              ),
              ListTile(
                leading: const Icon(Icons.copyright_outlined),
                title: const Text('Licensed under CC BY 4.0'),
                subtitle: const Text('The data is shown as received, only formatted for display.'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => openLink(context, Links.ccBy4),
              ),
              const _Header('Privacy'),
              const ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('No account, no ads, no tracking'),
                subtitle: Text(
                  'Your approximate location and searches are sent only to Open-Meteo to '
                  'get the forecast. Saved cities and cached forecasts stay on your phone.',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.policy_outlined),
                title: const Text('Privacy policy'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => openLink(context, Links.privacyPolicy),
              ),
              const _Header('App'),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Open-source licences'),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Weather Z',
                  applicationVersion: version,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}
