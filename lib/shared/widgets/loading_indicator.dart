import 'package:flutter/material.dart';

/// Skeleton shimmer placeholder for loading states.
class LoadingIndicator extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const LoadingIndicator({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.2),
                theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.2),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A full list skeleton for song tile placeholders.
class SongListSkeleton extends StatelessWidget {
  final int itemCount;

  const SongListSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const LoadingIndicator(
                width: 40,
                height: 40,
                borderRadius: 8,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LoadingIndicator(width: double.infinity, height: 14),
                    SizedBox(height: 6),
                    LoadingIndicator(width: 140, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LoadingIndicator(
                width: 32,
                height: 32,
                borderRadius: 16,
              ),
            ],
          ),
        );
      },
    );
  }
}
