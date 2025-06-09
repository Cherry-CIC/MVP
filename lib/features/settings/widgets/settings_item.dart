import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

class SettingsItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final String trailing;

  const SettingsItem(
      {super.key, required this.title, this.onTap, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.greyTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      trailing,
                      style: const TextStyle(
                        color: AppColors.greyTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.greyTextColor,
                      size: 26,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
