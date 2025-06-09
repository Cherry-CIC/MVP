import 'package:cherry_mvp/core/reusablewidgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/config/config.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigator = Provider.of<NavigationProvider>(context, listen: false);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              AppImages.welcomeBg,
              fit: BoxFit.cover,
            ),
          ),

          // Welcome Text at Top
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                AppStrings.welcome,
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greyNavFooter,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Pulsing Cherry Logo
          Center(
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: Image.asset(
                'assets/images/cherry_logo.png',
                width: 480,
                height: 280,
              ),
            ),
          ),

          // Bottom Buttons
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: PrimaryAppButton(
                    onPressed: () {
                      navigator.replaceWith(AppRoutes.login);
                    },
                    buttonText: AppStrings.login,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Register Button
                GestureDetector(
                  onTap: () {
                    navigator.replaceWith(AppRoutes.register);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.createAccount,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AppColors.black),
                      ),
                      const SizedBox(width: 5),
                      Image.asset(
                        AppImages.icButton,
                        width: 30,
                        height: 30,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
