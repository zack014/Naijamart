import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] in the right external app. Returns false instead of throwing
/// when nothing can handle it.
Future<bool> openExternal(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on PlatformException {
    return false;
  } catch (_) {
    return false;
  }
}

/// Only https links are opened for payments and policies.
Uri? safeHttpsUri(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}
