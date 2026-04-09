import 'package:flutter/material.dart';

class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    required this.height,
    this.width,
    this.label,
    this.borderRadius = 16,
  });

  final double height;
  final double? width;
  final String? label;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFE9E3D8),
      const Color(0xFFF5F2EC),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xFFE4DED6)),
        ),
        child: Center(
          child: Text(
            label ?? 'Preview',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

