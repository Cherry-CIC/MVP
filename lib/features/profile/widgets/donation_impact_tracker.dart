import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cherry_mvp/core/config/config.dart'; 
 
class DonationChart extends StatelessWidget {
  final double totalAmount;
  final Map<String, double> donations;
  final Map<String, Color> colors;

  const DonationChart({
    super.key,
    required this.totalAmount,
    required this.donations,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    List<PieChartSectionData> sections = donations.entries.map((entry) {
      return PieChartSectionData(
        color: colors[entry.key] ?? AppColors.greyTextColor,
        value: entry.value,
        title: '',
        radius: 15,
      );
    }).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: const Text(
            AppStrings.profile_your_donation_impact,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.greyTextColorTwo),
          ),
        ), 

        Padding(
          padding: EdgeInsets.only(top:8.0, bottom:32.0), 
          child: Align(
            alignment: Alignment.topLeft,
            child: const Text(
              AppStrings.profile_generosity_changes_lives,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.greyTextColorTwo
              ),
            )
          )
        ),

        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 180,
              child: PieChart(PieChartData(
                sections: sections,
                centerSpaceRadius: 90,
                sectionsSpace: 3,
              )),
            ),
            Column(
              children: [
                const Text(
                  AppStrings.profile_user_donation_total,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.greyTextColorTwo),
                ),
                Text(
                  '£${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.greyTextColorTwo),
                ),
              ],
            ),
          ],
        ), 

        Padding(
          padding: EdgeInsets.only(top:32.0, bottom:20.0), 
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: donations.entries.map((entry) {
              return LegendItem('${entry.key} £${entry.value.toStringAsFixed(0)}',
                colors[entry.key]!);
            }).toList(),
          )
        )
      ],
    );
  }
}

class LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const LegendItem(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
              shape: BoxShape.circle, // Makes the container round
              color: color),
          width: 12,
          height: 12,
        ),

        Padding(
          padding: EdgeInsets.only(left:6.0), 
          child: Text(label,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              color: AppColors.greyTextColorTwo,
              fontSize: 14,
            )
          )
        )
      ],
    );
  }
}