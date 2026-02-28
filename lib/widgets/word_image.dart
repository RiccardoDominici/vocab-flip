import 'package:flutter/material.dart';
import '../utils/image_helper.dart';

class WordImage extends StatelessWidget {
  final String keyword;
  final double size;
  final BorderRadius? borderRadius;

  const WordImage({
    super.key,
    required this.keyword,
    this.size = 120,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: Image.network(
        ImageHelper.wordImageUrl(keyword, w: size.toInt(), h: size.toInt()),
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: borderRadius ?? BorderRadius.circular(16),
            ),
            child: Center(
              child: SizedBox(
                width: size * 0.3,
                height: size * 0.3,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: borderRadius ?? BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              size: size * 0.3,
              color: Colors.grey[400],
            ),
          );
        },
      ),
    );
  }
}
