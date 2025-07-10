import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/reusablewidgets/form/button_style.dart';
import 'package:cherry_mvp/core/reusablewidgets/loading_view.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class LoginSignupCard extends StatelessWidget {
  final VoidCallback onClose;
  final AuthMode mode;
  const LoginSignupCard({super.key, required this.onClose, required this.mode});

  @override
  Widget build(BuildContext context) {
    final navigator = Provider.of<NavigationProvider>(context, listen: false);
    final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);

    final bool isLogin = mode == AuthMode.login;
    return Card(
      color: AppColors.bgColor,
      margin: EdgeInsets.zero,
      elevation: 20,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(isLogin ? AppStrings.login : AppStrings.register,
                      style: AppTextStyles.signupCardText
                      //  TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.black,
                  ),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 16),

            SocialLoginButton(
              label: AppStrings.continueWithApple,
              imagetext: AppImages.authAppleIcon,
              onPressed: () {},
            ),
            const SizedBox(height: 10),
            //adding loading
            Consumer<LoginViewModel>(
              builder: (context, viewModel, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (viewModel.status.type == StatusType.failure) {
                    Fluttertoast.showToast(
                        msg: viewModel.status.message == null
                            ? ""
                            : "${isLogin ? AppStrings.login : AppStrings.register} Failed");
                    viewModel.clearStatus();
                  } else if (viewModel.status.type == StatusType.success) {
                    Fluttertoast.showToast(
                        msg:
                            "${isLogin ? AppStrings.login : AppStrings.register} Successful");
                    viewModel.clearStatus();
                    //move to home
                    navigator.replaceWith(AppRoutes.home);
                  }
                });
                return viewModel.status.type == StatusType.loading
                    ? const LoadingView()
                    : SocialLoginButton(
                        label: AppStrings.continueWithGoogle,
                        imagetext: AppImages.authGoogleIcon,
                        onPressed: () {
                          loginViewModel.signInWithGoogle();
                        },
                      );
              },
            ),

            const SizedBox(height: 10),
            // facebook
            // SocialLoginButton(
            //   label: 'Continue with Facebook',
            //   icon: Icons.facebook,
            //   color: Colors.blueAccent,
            //   onPressed: () {},
            // ),
            // const SizedBox(height: 12),

            Row(
              children: const [
                Expanded(child: Divider(color: AppColors.greyNavFooter)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(AppStrings.or,
                      style: TextStyle(color: AppColors.greyNavFooter)),
                ),
                Expanded(child: Divider(color: AppColors.greyNavFooter)),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                isLogin
                    ? navigator.replaceWith(AppRoutes.login)
                    : navigator.replaceWith(AppRoutes.register);
              },
              child: const Text(
                AppStrings.continueWithEmail,
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
