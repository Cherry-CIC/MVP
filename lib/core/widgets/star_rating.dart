import 'package:cherry_mvp/core/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/models/user_section.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.userInformation,
    this.starSize = 24.0,
  });

  final UserInformation userInformation;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    final rating = userInformation.rating.clamp(0.0, maxStarRating.toDouble());
    final fullStars = rating.floor();
    final hasHalfStar = rating.ceil() != rating.floor();
    final emptyStars = maxStarRating - rating.ceil();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < fullStars; i++) Icon(Icons.star, color: AppColors.yellow, size: starSize),
        if (hasHalfStar) Icon(Icons.star_half, color: AppColors.yellow, size: starSize),
        for (var i = 0; i < emptyStars; i++) Icon(Icons.star_border, color: AppColors.yellow, size: starSize),
      ],
    );
  }
}
