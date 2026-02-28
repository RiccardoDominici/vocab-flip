class ImageHelper {
  static String wordImageUrl(String keyword, {int w = 300, int h = 300}) {
    final q = Uri.encodeComponent(keyword.toLowerCase().replaceAll(' ', ','));
    // loremflickr with lock parameter for deterministic images per keyword
    return 'https://loremflickr.com/$w/$h/$q?lock=${keyword.hashCode.abs()}';
  }
}
