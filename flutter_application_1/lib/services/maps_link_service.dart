import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Membuka pencarian Google Maps untuk nama restoran dan kabupaten/kota terkait.
Future<bool> openInGoogleMaps(String name, String? kabupatenKota) async {
  try {
    final query = '$name ${kabupatenKota ?? ''}'.trim();
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return launched;
  } catch (e) {
    debugPrint('Error membuka Google Maps: $e');
    return false;
  }
}

/// Menghasilkan label tampilan rapi untuk jenis sajian restoran.
String? dishLabel(String? dishType) {
  if (dishType == null) return null;
  final trimmed = dishType.trim();
  if (trimmed.isEmpty) return null;
  final cleaned = trimmed.replaceAll('_', ' ');
  return cleaned
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}
