import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool animate;
  final int barCount;
  final double maxHeight;
  final double barWidth;
  final double spacing;

  const WaveformVisualizer({
    super.key,
    this.animate = true,
    this.barCount = 13,
    this.maxHeight = 42,
    this.barWidth = 5,
    this.spacing = 6,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const List<double> _baseProfile = [
    0.25, 0.45, 0.72, 0.48, 0.85, 0.62, 1.0, 0.68, 0.82, 0.45, 0.65, 0.40, 0.25,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          height: widget.maxHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final profile = _baseProfile[index % _baseProfile.length];
              final phase = (_controller.value * 2 * math.pi) + (index * 0.55);
              final factor = widget.animate
                  ? (0.55 + 0.45 * math.sin(phase).abs()) * profile
                  : profile * 0.85;
              final height = math.max(8.0, widget.maxHeight * factor);

              final isCenter = (index - widget.barCount ~/ 2).abs() <= 2;
              final color = isCenter
                  ? (index.isEven ? AppColors.waveTeal : AppColors.waveCyan)
                  : AppColors.waveBlue;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                child: Container(
                  width: widget.barWidth,
                  height: height,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(widget.barWidth),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
