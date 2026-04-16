import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Base colors for the shimmer effect (classic Facebook / Instagram feel).
const Color _kShimmerBase = Color(0xFFE5E7EB);
const Color _kShimmerHighlight = Color(0xFFF5F5F5);

/// An animated skeleton placeholder with a smooth left-to-right shimmer.
///
/// Keeps its public API (`width`, `height`, `borderRadius`) so existing
/// callers don't need to change.
class SkeletonLoader extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    )..repeat();
    // Linear tween sweeps the highlight band from off-screen left to
    // off-screen right for a smooth continuous shimmer.
    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(8);
    return ClipRRect(
      borderRadius: radius,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return CustomPaint(
            painter: _ShimmerPainter(position: _animation.value),
            size: Size(widget.width ?? 0, widget.height ?? 0),
            child: SizedBox(
              width: widget.width,
              height: widget.height,
            ),
          );
        },
      ),
    );
  }
}

/// Paints a diagonal base→highlight→base gradient whose highlight band is
/// positioned via `Alignment(position, 0)`, driven by the parent tween.
class _ShimmerPainter extends CustomPainter {
  final double position;

  const _ShimmerPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment(position - 1, -1),
      end: Alignment(position + 1, 1),
      colors: const [_kShimmerBase, _kShimmerHighlight, _kShimmerBase],
      stops: const [0.25, 0.5, 0.75],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) =>
      oldDelegate.position != position;
}

/// A cached network image with an animated shimmer placeholder.
///
/// While loading it shows the shimmering [SkeletonLoader]; on error it
/// falls back to a muted grey box with a small icon.
class SkeletonImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return SkeletonLoader(
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }

    final radius = borderRadius ?? BorderRadius.zero;
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => SkeletonLoader(
          width: width,
          height: height,
          borderRadius: borderRadius,
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: _kShimmerBase,
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            size: 20,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}
