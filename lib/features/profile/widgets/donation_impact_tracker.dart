import 'package:cherry_mvp/core/config/app_colors.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
        color:
            colors[entry.key] ?? Theme.of(context).colorScheme.onSurfaceVariant,
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
          child: Text(
            AppStrings.profile_your_donation_impact,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            AppStrings.profile_generosity_changes_lives,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: 32),
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
                Text(
                  AppStrings.profile_user_donation_total,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text(
                  '£${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          children: donations.entries.map((entry) {
            return LegendItem('${entry.key} £${entry.value.toStringAsFixed(0)}',
                colors[entry.key]!);
          }).toList(),
        ),
        SizedBox(height: 20),
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
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            )),
      ],
    );
  }
}
