import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class VitaStepAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? stepText;
  final double? progress;
  final bool uppercaseStep;
  final VoidCallback? onBack;

  const VitaStepAppBar({
    super.key,
    required this.title,
    this.stepText,
    this.progress,
    this.uppercaseStep = false,
    this.onBack,
  });

  @override
  Size get preferredSize => Size.fromHeight(progress != null ? 60 : 56);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack ?? () => Navigator.maybePop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (stepText != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              stepText!,
                              style: TextStyle(
                                fontSize: uppercaseStep ? 12 : 13,
                                fontWeight: uppercaseStep ? FontWeight.w800 : FontWeight.w600,
                                color: uppercaseStep
                                    ? AppColors.primaryDeep
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDeep,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (progress != null)
              LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: AppColors.primaryTint,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryDeep),
              )
            else
              const Divider(height: 1, color: AppColors.borderLight),
          ],
        ),
      ),
    );
  }
}
