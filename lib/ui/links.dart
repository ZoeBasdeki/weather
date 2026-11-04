import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// External links used across the app.
abstract final class Links {
  static final openMeteo = Uri.https('open-meteo.com', '/');
  static final ccBy4 = Uri.https('creativecommons.org', '/licenses/by/4.0/');
  static final privacyPolicy =
      Uri.https('github.com', '/ZoeBasdeki/weather/blob/main/PRIVACY.md');
}

/// Opens [url] in the browser; shows a snackbar if no app can handle it.
Future<void> openLink(BuildContext context, Uri url) async {
  final messenger = ScaffoldMessenger.of(context);
  bool ok;
  try {
    ok = await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) messenger.showSnackBar(SnackBar(content: Text('Could not open $url')));
}

/// "Weather data by Open-Meteo.com", linked. CC BY 4.0 requires this next to
/// every place the data is shown.
class OpenMeteoAttribution extends StatelessWidget {
  const OpenMeteoAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: TextButton(
        onPressed: () => openLink(context, Links.openMeteo),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          textStyle: theme.textTheme.bodySmall,
        ),
        child: const Text('Weather data by Open-Meteo.com'),
      ),
    );
  }
}
