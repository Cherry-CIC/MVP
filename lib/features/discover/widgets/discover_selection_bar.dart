import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:flutter/material.dart';

class DiscoverSelectionBar extends StatefulWidget {
  const DiscoverSelectionBar({super.key});

  @override
  State<DiscoverSelectionBar> createState() => _DiscoverSelectionBarState();
}

class _DiscoverSelectionBarState extends State<DiscoverSelectionBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(3),
        child: SizedBox(
          width: double.infinity,
          height: 40,// Ensures the Row takes the full width available
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "Popular",
                      style: AppTextStyles.selectedOption,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.greyBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "Smaller Charities",
                      style: AppTextStyles.unselectedOption,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.greyBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "Local to you",
                      style: AppTextStyles.unselectedOption,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
