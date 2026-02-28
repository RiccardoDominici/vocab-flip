import 'package:flutter/material.dart';
import '../utils/image_helper.dart';

/// Displays a Wikipedia / Wikimedia Commons image for a keyword.
/// Resolves the URL asynchronously with fallback chain, and retries once
/// if the resolved image itself fails to load.
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
  bool _retriedAfterLoadError = false;

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
      _retriedAfterLoadError = false;
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

  /// Called when Image.network fails to load the resolved URL.
  /// Invalidates the cache and retries resolution once so the fallback chain
  /// can try a different source.
  void _onLoadError() {
    if (_retriedAfterLoadError) return; // only retry once
    _retriedAfterLoadError = true;
    ImageHelper.invalidate(widget.keyword);
    setState(() {
      _resolved = false;
      _imageUrl = null;
    });
    _resolve();
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
          // If the image itself failed to load, invalidate and retry once.
          if (!_retriedAfterLoadError) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _onLoadError());
          }
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
