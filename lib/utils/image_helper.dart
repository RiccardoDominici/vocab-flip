import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class ImageHelper {
  // In-memory cache: keyword → resolved image URL (or empty string on failure).
  static final Map<String, String> _cache = {};

  /// Desired thumbnail width used for card display.
  static const int _thumbWidth = 600;

  /// Resolve a keyword to a Wikipedia thumbnail URL.
  /// Returns the image URL or `null` if nothing was found.
  static Future<String?> resolveImageUrl(String keyword) async {
    // Check cache first.
    if (_cache.containsKey(keyword)) {
      final cached = _cache[keyword]!;
      return cached.isEmpty ? null : cached;
    }

    try {
      final encoded = Uri.encodeComponent(keyword);
      final uri = Uri.parse(
          'https://en.wikipedia.org/api/rest_v1/page/summary/$encoded');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final thumbnail = data['thumbnail'] as Map<String, dynamic>?;
        if (thumbnail != null) {
          final source = thumbnail['source'] as String;
          // Replace the default width (usually 330px) with our desired width.
          final resized = _resizeThumb(source, _thumbWidth);
          _cache[keyword] = resized;
          return resized;
        }
      }
    } catch (_) {
      // Network error – fall through.
    }

    _cache[keyword] = ''; // Cache the miss so we don't retry.
    return null;
  }

  /// Precache the resolved image so Flutter's image cache is warm.
  static Future<void> precacheWord(BuildContext context, String keyword) async {
    final url = await resolveImageUrl(keyword);
    if (url != null && context.mounted) {
      precacheImage(NetworkImage(url), context);
    }
  }

  /// Resize a Wikimedia thumbnail URL to a different width.
  /// Thumb URLs look like: .../thumb/.../330px-Filename.jpg
  static String _resizeThumb(String url, int width) {
    return url.replaceFirstMapped(
      RegExp(r'/(\d+)px-'),
      (m) => '/${width}px-',
    );
  }
}
