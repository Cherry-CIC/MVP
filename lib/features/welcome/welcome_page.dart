import 'dart:ui';
import 'package:cherry_mvp/features/welcome/widgets/signup_card.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';

enum AuthMode { login, signup }

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

  //for card to show up
  bool showBottomCard = false;
  AuthMode? authMode;
  void toggleCard(AuthMode mode) {
    setState(() {
      authMode = mode;
      showBottomCard = true;
    });
  }

  void closeCard() {
    setState(() => showBottomCard = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cardHeight = 400;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppImages.welcomeBg,
              fit: BoxFit.cover,
            ),
          ),

          Center(
            child: FittedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Image.asset(
                      //change
                      AppImages.cherryLogo,
                      width: 350,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.giveInStyle,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  SizedBox(
                    height: showBottomCard
                        ? MediaQuery.of(context).size.height * 0.1
                        : 0,
                  )
                ],
              ),
            ),
          ),
          if (showBottomCard)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: showBottomCard ? 1.0 : 0.0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: closeCard, // This will close the card
                child: Container(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.3), // dim color
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Buttons
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      toggleCard(AuthMode.login);
                    },
                    child: Text(AppStrings.login),
                  ),
                ),

                const SizedBox(height: 20),

                // Register Button
                GestureDetector(
                  onTap: () {
                    toggleCard(AuthMode.signup);
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
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: 0,
            right: 0,
            bottom: showBottomCard ? 0 : -cardHeight,
            child: AuthCard(
              onClose: closeCard,
              mode: authMode ?? AuthMode.login,
            ),
          ),
        ],
      ),
    );
  }
}