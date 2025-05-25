import 'package:flutter/material.dart';
 
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/profile/widgets/donation_impact_tracker.dart';
import 'package:cherry_mvp/features/profile/widgets/profilepage_userActivity_cards.dart';
import 'package:cherry_mvp/features/profile/widgets/user_information_section.dart'; 
import 'package:cherry_mvp/features/profile/profile_model.dart';  
import 'package:cherry_mvp/core/models/model.dart'; 


class ProfilePage extends StatelessWidget {
  final List<Color> charityColors = [
    AppColors.piechart_red,
    AppColors.blueBgColor,
    AppColors.piechart_green,
    AppColors.piechart_purple
  ];

  final List<double> charityValues = [40, 30, 20, 10];

  final List<String> charityLabels = [
    'Charity A',
    'Charity B',
    'Charity C',
    'Charity D'
  ];

  final ProfileItem profile = dummyProfileData[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppStrings.profileText,
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
                  username: profile.username,
                  awards: profile.awards,
                  location: profile.location,
                  reviewsCount: profile.reviewsCount,
                  followersCount: profile.followersCount,
                  followingCount: profile.followingCount,
                  rating: profile.rating,
                  hasBuyerDiscounts: profile.hasBuyerDiscounts,
                ), 

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
                Padding(
                  padding: EdgeInsets.only(bottom:20.0),
                  child: Row(
                    children: [
                      ProfilepageUseractivityCards(
                          title: AppStrings.profile_userActivity_bought,
                          value: '0'), 

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal:10.0), 
                        child: ProfilepageUseractivityCards(
                          title: AppStrings.profile_userActivity_sold,
                          value: '0'
                        )
                      ),

                      ProfilepageUseractivityCards(
                          title: AppStrings.profile_userActivity_total,
                          value: '0'),
                    ],
                  ),
                ),
 
              ],
            ),
          ),
        ),
      ),
    );
  }
}