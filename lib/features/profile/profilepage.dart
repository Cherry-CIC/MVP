import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfilePage extends StatelessWidget {
  final List<Color> charityColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange
  ];

  final List<double> charityValues = [40, 30, 20, 10];

  final List<String> charityLabels = [
    'Charity A',
    'Charity B',
    'Charity C',
    'Charity D'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'User Donation Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 20),
            Expanded(
              child: Row(
                children: [
                  // Pie Chart
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: List.generate(4, (index) {
                          return PieChartSectionData(
                            color: charityColors[index],
                            value: charityValues[index],
                            title: '${charityValues[index]}%',
                            radius: 50,
                            titleStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          );
                        }),
                        sectionsSpace: 4,
                        centerSpaceRadius: 30,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Bar Chart
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                if (value.toInt() < charityLabels.length) {
                                  return Text(
                                    charityLabels[value.toInt()],
                                    style: TextStyle(fontSize: 10),
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),
                          ),
                          topTitles: AxisTitles(),
                          rightTitles: AxisTitles(),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(4, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: charityValues[index],
                                color: charityColors[index],
                                width: 20,
                              )
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
