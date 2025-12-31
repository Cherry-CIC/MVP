import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/features/profile/widgets/donation_impact_tracker.dart';
import 'package:cherry_mvp/features/profile/widgets/user_activity_cards.dart';
import 'package:cherry_mvp/features/profile/widgets/user_information_section.dart';
import 'package:cherry_mvp/features/profile/widgets/user_order_details.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/router/router.dart';

import '../auth/auth_view_model.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<Color> charityColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];

  final List<double> charityValues = [40, 30, 20, 10];

  final List<String> charityLabels = [
    'Charity A',
    'Charity B',
    'Charity C',
    'Charity D',
  ];

  final Map<String, dynamic> userInfoMap = {
    'username': AppStrings.profileUserInfoUsername,
    'location': AppStrings.profileUserInfoLocation,
    'reviewsCount': 0,
    'followersCount': 0,
    'followingCount': 0,
    'rating': 0.0,
    'awards': 0,
    'hasBuyerDiscounts': true,
  };
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<AuthViewModel>().loadCurrentUser();
    });
  }

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
        title: Text(AppStrings.profileUserInfoTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
              UserOrderDetails(),
              SizedBox(height: 16),
              DonationChart(
                totalAmount: 365.00,
                donations: {
                  'BHF': 183,
                  'Samaritans': 92,
                  'Cancer Research': 47,
                  'RNLI': 43,
                },
                colors: {
                  'BHF': AppColors.red,
                  'Samaritans': AppColors.pink,
                  'Cancer Research': AppColors.green, //pink
                  'RNLI': AppColors.purple, //blue
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                height: 96,
                child: Row(
                  children: [
                    Expanded(
                      child: UserActivityCards(
                        title: AppStrings.profileUserActivityBought,
                        value: '0',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: UserActivityCards(
                        title: AppStrings.profileUserActivitySold,
                        value: '0',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: UserActivityCards(
                        title: AppStrings.profileUserActivityTotal,
                        value: '0',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  child: Text(AppStrings.share),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
