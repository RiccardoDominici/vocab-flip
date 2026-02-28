import 'package:flutter/widgets.dart';

class ImageHelper {
  static String wordImageUrl(String keyword, {int w = 300, int h = 300}) {
    final q = Uri.encodeComponent(keyword.toLowerCase().replaceAll(' ', ','));
    // loremflickr with lock parameter for deterministic images per keyword
    return 'https://loremflickr.com/$w/$h/$q?lock=${keyword.hashCode.abs()}';
  }

  /// Precache an image for a word so it's ready when the card appears.
  static Future<void> precacheWord(BuildContext context, String keyword,
      {int w = 400, int h = 600}) {
    final url = wordImageUrl(keyword, w: w, h: h);
    return precacheImage(NetworkImage(url), context);
  }
}
