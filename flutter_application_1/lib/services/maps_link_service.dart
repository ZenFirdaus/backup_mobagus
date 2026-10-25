import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

export '../core/constants/dish_types.dart' show dishLabel;

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
