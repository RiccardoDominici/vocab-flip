import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shimmer/shimmer.dart';
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

  Widget _buildShimmer(BorderRadius radius) {
    return ClipRRect(
      borderRadius: radius,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(16);

    if (!_resolved) {
      return _buildShimmer(radius);
    }

    if (_imageUrl == null) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          color: Colors.grey[200],
          child: Icon(
            Iconsax.gallery_slash,
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
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.white),
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
              Iconsax.gallery_slash,
              size: 40,
              color: Colors.grey[400],
            ),
          );
        },
      ),
    );
  }
}
