import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/reusablewidgets/form/button_style.dart';
import 'package:cherry_mvp/features/profile/widgets/donation_impact_tracker.dart';
import 'package:cherry_mvp/features/profile/widgets/profilepage_userActivity_cards.dart';
import 'package:cherry_mvp/features/profile/widgets/user_information_section.dart';
import 'package:cherry_mvp/features/profile/widgets/user_order_details.dart';
import 'package:flutter/material.dart';

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
  final Map<String, dynamic> userInfoMap = {
    'username': AppStrings.profile_user_info_username,
    'location': AppStrings.profile_user_info_location,
    'reviewsCount': 0,
    'followersCount': 0,
    'followingCount': 0,
    'rating': 0.0,
    'awards': 0,
    'hasBuyerDiscounts': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //profile header
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppStrings.profile_user_info_title,
          style: AppTextStyles.screen_title,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //user information section
                UserInformationSection(
                  userInformationSection: UserInformation.fromJson(userInfoMap),
                ),

                // Pie and bar charts side by side (commenting if need in future)
                // SizedBox(
                //   height: 300, // set fixed height for chart area
                //   child: Row(
                //     children: [
                //       Expanded(
                //         child: PieChart(
                //           PieChartData(
                //             sections: List.generate(4, (index) {
                //               return PieChartSectionData(
                //                 color: charityColors[index],
                //                 value: charityValues[index],
                //                 title: '${charityValues[index]}%',
                //                 radius: 50,
                //                 titleStyle: TextStyle(
                //                     fontSize: 14,
                //                     fontWeight: FontWeight.bold,
                //                     color: Colors.white),
                //               );
                //             }),
                //             sectionsSpace: 4,
                //             centerSpaceRadius: 30,
                //           ),
                //         ),
                //       ),
                //       SizedBox(width: 16),
                //       Expanded(
                //         child: BarChart(
                //           BarChartData(
                //             alignment: BarChartAlignment.spaceAround,
                //             titlesData: FlTitlesData(
                //               leftTitles: AxisTitles(
                //                 sideTitles: SideTitles(showTitles: true),
                //               ),
                //               bottomTitles: AxisTitles(
                //                 sideTitles: SideTitles(
                //                   showTitles: true,
                //                   getTitlesWidget: (value, _) {
                //                     if (value.toInt() < charityLabels.length) {
                //                       return Text(
                //                         charityLabels[value.toInt()],
                //                         style: TextStyle(fontSize: 10),
                //                       );
                //                     }
                //                     return SizedBox.shrink();
                //                   },
                //                 ),
                //               ),
                //               topTitles: AxisTitles(),
                //               rightTitles: AxisTitles(),
                //             ),
                //             borderData: FlBorderData(show: false),
                //             barGroups: List.generate(4, (index) {
                //               return BarChartGroupData(
                //                 x: index,
                //                 barRods: [
                //                   BarChartRodData(
                //                     toY: charityValues[index],
                //                     color: charityColors[index],
                //                     width: 20,
                //                   )
                //                 ],
                //               );
                //             }),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                //user order details
                UserOrderDetails(),
                //donation chart
                DonationChart(
                  totalAmount: 365.00,
                  donations: {
                    'BHF': 183,
                    'Samaritans': 92,
                    'Cancer Research': 47,
                    'RNLI': 43,
                  },
                  colors: {
                    'BHF': AppColors.piechart_red,
                    'Samaritans': AppColors.piechart_pink,
                    'Cancer Research': AppColors.piechart_green, //pink
                    'RNLI': AppColors.piechart_purple, //blue
                  },
                ),

                // User activity cards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ProfilepageUseractivityCards(
                          title: AppStrings.profile_userActivity_bought,
                          value: '0'),
                      SizedBox(width: 10),
                      ProfilepageUseractivityCards(
                          title: AppStrings.profile_userActivity_sold,
                          value: '0'),
                      SizedBox(width: 10),
                      ProfilepageUseractivityCards(
                          title: AppStrings.profile_userActivity_total,
                          value: '0'),
                    ],
                  ),
                ),

                SizedBox(height: 20),
                CustomButton(
                  title: AppStrings.share,
                  onPressed: () {},
                ),
                SizedBox(height: 10)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
