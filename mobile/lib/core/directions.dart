import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../shared/ui.dart';
import 'locale.dart';

/// Opens walking directions to a point in the phone's maps app.
Future<void> openDirections(BuildContext context, double lat, double lng) async {
  final google = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking');
  final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
  try {
    if (!await launchUrl(google, mode: LaunchMode.externalApplication)) {
      await launchUrl(geo, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    if (context.mounted) showSnack(context, context.l10n.errDirections, error: true);
  }
}
