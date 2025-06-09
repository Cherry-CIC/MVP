import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/profile/widgets/donation_impact_tracker.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.profile_user_donation_Summary,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
       
                SizedBox(height: 20),
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
                SizedBox(height: 20),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilepageUseractivityCards extends StatelessWidget {
  final String title;
  final String value;

  const ProfilepageUseractivityCards({
    required this.title,
    required this.value,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}