import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/reusablewidgets/primary_button.dart';
import 'package:cherry_mvp/features/profile/widgets/donation_impact_tracker.dart';
import 'package:cherry_mvp/features/profile/widgets/profilepage_userActivity_cards.dart';
import 'package:cherry_mvp/features/profile/widgets/user_information_section.dart';
import 'package:cherry_mvp/features/profile/widgets/user_order_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/router/router.dart';

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

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {

    void navigateToSettings() {
      final navigator = Provider.of<NavigationProvider>(context, listen: false);
      navigator.navigateTo(AppRoutes.settingspage);
    }

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
                  onSettingsPressed: () {
                    navigateToSettings();
                  },
                ),
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

                const SizedBox(height: 20),
                PrimaryAppButton(
                  onPressed: () {},
                  buttonText: AppStrings.share,
                  height: 60.0,
                ),

                const SizedBox(height: 10)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
