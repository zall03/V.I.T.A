import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'waveform_visualizer.dart';

class AudioMemoPlayer extends StatefulWidget {
  final String fileLabel;
  final int totalSeconds;

  const AudioMemoPlayer({
    super.key,
    required this.fileLabel,
    this.totalSeconds = 24,
  });

  @override
  State<AudioMemoPlayer> createState() => _AudioMemoPlayerState();
}

class _AudioMemoPlayerState extends State<AudioMemoPlayer> {
  bool _isPlaying = false;
  int _currentSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      if (_currentSeconds >= widget.totalSeconds) {
        _currentSeconds = 0;
      }
      setState(() => _isPlaying = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_currentSeconds >= widget.totalSeconds) {
          _timer?.cancel();
          setState(() => _isPlaying = false);
        } else {
          setState(() => _currentSeconds++);
        }
      });
    }
  }

  String _fmt(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalSeconds == 0
        ? 0.0
        : (_currentSeconds / widget.totalSeconds).clamp(0.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isPlaying ? AppColors.primaryTintSoft : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isPlaying ? AppColors.primaryBlue : AppColors.border,
          width: _isPlaying ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _togglePlay,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPlaying ? AppColors.primaryDeep : AppColors.primaryBlue,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileLabel,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPlaying
                      ? '${_fmt(_currentSeconds)} / ${_fmt(widget.totalSeconds)} • Memutar Rekaman...'
                      : '${_fmt(widget.totalSeconds)} • Ketuk ▶ untuk putar rekaman',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: _isPlaying ? FontWeight.w600 : FontWeight.w500,
                    color: _isPlaying
                        ? AppColors.primaryBlue
                        : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _isPlaying ? (progress == 0 ? 0.15 : progress) : 0.04,
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          WaveformVisualizer(
            animate: _isPlaying,
            barCount: 7,
            maxHeight: 24,
            barWidth: 3,
            spacing: 2.5,
          ),
        ],
      ),
    );
  }
}
