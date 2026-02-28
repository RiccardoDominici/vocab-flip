import 'package:flutter/material.dart';
import '../utils/image_helper.dart';

/// Displays a Wikipedia image for a keyword.
/// Resolves the URL asynchronously, shows a placeholder while loading.
class WordImage extends StatefulWidget {
  final String keyword;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const WordImage({
    super.key,
    required this.keyword,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<WordImage> createState() => _WordImageState();
}

class _WordImageState extends State<WordImage> {
  String? _imageUrl;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(WordImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keyword != widget.keyword) {
      _resolved = false;
      _imageUrl = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final url = await ImageHelper.resolveImageUrl(widget.keyword);
    if (mounted) {
      setState(() {
        _imageUrl = url;
        _resolved = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    if (!_resolved) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          color: Colors.grey[200],
          child: const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      );
    }

    if (_imageUrl == null) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          color: Colors.grey[200],
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        _imageUrl!,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
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
            color: Colors.grey[200],
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          );
        },
      ),
    );
  }
}
