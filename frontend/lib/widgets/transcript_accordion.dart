import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class TranscriptAccordion extends StatefulWidget {
  final String transcript;
  final String durationText;

  const TranscriptAccordion({
    super.key,
    required this.transcript,
    this.durationText = '00:24',
  });

  @override
  State<TranscriptAccordion> createState() => _TranscriptAccordionState();
}

class _TranscriptAccordionState extends State<TranscriptAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _expanded ? Colors.white : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _expanded ? AppColors.primaryBlue : AppColors.border,
            width: _expanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _expanded
                        ? '🎙 Transkrip Suara Perawat (Tutup ^)'
                        : '🎙 Lihat Transkrip Suara Asli',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDeep,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _expanded
                      ? 'Whisper AI • ${widget.durationText}'
                      : '✓ 100% Akurat • ${widget.durationText} ⌄',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _expanded
                        ? AppColors.primaryBlue
                        : AppColors.navyDark,
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Text(
                widget.transcript,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
