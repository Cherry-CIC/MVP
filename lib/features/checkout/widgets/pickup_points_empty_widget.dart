import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

class PickupPointsEmptyWidget extends StatelessWidget {
  const PickupPointsEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              Icons.location_on,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              AppStrings.noPickupPointAvailable,
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
