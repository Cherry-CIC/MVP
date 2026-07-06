import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

class PickupPointsLoadingWidget extends StatelessWidget {
  const PickupPointsLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              AppStrings.loadingPickupPoint,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
