import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class ImageHelper {
  /// In-memory cache: keyword → resolved image URL (or empty string if all
  /// sources failed).
  static final Map<String, String> _cache = {};

  /// Desired thumbnail width for card display.
  static const int _thumbWidth = 600;

  /// Resolve a keyword to an image URL using a fallback chain:
  ///   1. Wikipedia article thumbnail
  ///   2. Wikimedia Commons image search
  static Future<String?> resolveImageUrl(String keyword) async {
    if (_cache.containsKey(keyword)) {
      final cached = _cache[keyword]!;
      return cached.isEmpty ? null : cached;
    }

    // 1) Try Wikipedia article summary.
    final wiki = await _tryWikipedia(keyword);
    if (wiki != null) {
      _cache[keyword] = wiki;
      return wiki;
    }

    // 2) Try Wikimedia Commons search.
    final commons = await _tryCommonsSearch(keyword);
    if (commons != null) {
      _cache[keyword] = commons;
      return commons;
    }

    _cache[keyword] = '';
    return null;
  }

  /// Remove a keyword from cache so the next [resolveImageUrl] call re-fetches.
  static void invalidate(String keyword) {
    _cache.remove(keyword);
  }

  /// Precache the resolved image so Flutter's image cache is warm.
  static Future<void> precacheWord(
      BuildContext context, String keyword) async {
    final url = await resolveImageUrl(keyword);
    if (url != null && context.mounted) {
      precacheImage(NetworkImage(url), context);
    }
  }

  // ---------------------------------------------------------------------------
  // Source 1 – Wikipedia REST API
  // ---------------------------------------------------------------------------
  static Future<String?> _tryWikipedia(String keyword) async {
    try {
      final encoded = Uri.encodeComponent(keyword);
      final uri = Uri.parse(
          'https://en.wikipedia.org/api/rest_v1/page/summary/$encoded');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final thumbnail = data['thumbnail'] as Map<String, dynamic>?;
        if (thumbnail != null) {
          return _resizeThumb(thumbnail['source'] as String, _thumbWidth);
        }
      }
    } catch (_) {}
    return null;
  }

  // ---------------------------------------------------------------------------
  // Source 2 – Wikimedia Commons search
  // ---------------------------------------------------------------------------
  static Future<String?> _tryCommonsSearch(String keyword) async {
    try {
      final q = Uri.encodeComponent(keyword);
      final uri = Uri.parse(
        'https://commons.wikimedia.org/w/api.php'
        '?action=query'
        '&generator=search'
        '&gsrsearch=$q'
        '&gsrnamespace=6'
        '&gsrlimit=3'
        '&prop=imageinfo'
        '&iiprop=url|mime'
        '&iiurlwidth=$_thumbWidth'
        '&format=json'
        '&origin=*',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'VocabFlip/1.1 (vocabulary flashcard app)',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final pages = (data['query'] as Map<String, dynamic>?)?['pages']
            as Map<String, dynamic>?;
        if (pages != null) {
          // Pick the first result that is actually a raster image.
          for (final page in pages.values) {
            final info =
                ((page as Map<String, dynamic>)['imageinfo'] as List?)
                    ?.firstOrNull as Map<String, dynamic>?;
            if (info == null) continue;
            final mime = info['mime'] as String? ?? '';
            if (!mime.startsWith('image/') ||
                mime.contains('svg') ||
                mime.contains('tiff')) {
              continue;
            }
            final thumb = info['thumburl'] as String?;
            if (thumb != null) return thumb;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Resize a Wikimedia thumbnail URL to a different width.
  static String _resizeThumb(String url, int width) {
    return url.replaceFirstMapped(
      RegExp(r'/(\d+)px-'),
      (m) => '/${width}px-',
    );
  }
}
