import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/theme_extension.dart';

class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    super.key,
    this.height = 78,
    this.radius = 28,
    this.margin,
  });

  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    final base = colors.isLight ? const Color(0xFFE9F0F4) : const Color(0xFF16222C);
    final highlight = colors.isLight ? const Color(0xFFF7FAFC) : const Color(0xFF1E2E3A);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1400),
      child: Container(
        height: height,
        margin: margin ?? const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// A column of skeleton cards
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.count = 5});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => const ShimmerSkeleton(
          height: 78,
          radius: 28,
          margin: EdgeInsets.only(bottom: 14),
        ),
      ),
    );
  }
}
