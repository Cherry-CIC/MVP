import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/welcome/widgets/button_style.dart';
import 'package:cherry_mvp/features/welcome/widgets/loading_view.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/login/login_viewmodel.dart';
import 'package:cherry_mvp/features/welcome/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class AuthCard extends StatelessWidget {
  final VoidCallback onClose;
  final AuthMode mode;
  const AuthCard({super.key, required this.onClose, required this.mode});

  @override
  Widget build(BuildContext context) {
    final navigator = Provider.of<NavigationProvider>(context, listen: false);
    final loginViewModel = Provider.of<LoginViewModel>(context, listen: false);

    final bool isLogin = mode == AuthMode.login;
    return Consumer<LoginViewModel>(builder: (context, viewModel, child) {
      final bool isLoading = viewModel.status.type == StatusType.loading;
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
      return Card(
        color: Color(0xFFFAFAFA),
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
                    child: Text(
                        isLogin ? AppStrings.login : AppStrings.register,
                        style: Theme.of(context).textTheme.titleMedium
                        //  TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.black,
                    ),
                    onPressed: isLoading ? null : onClose,
                  ),
                ],
              ),
              ...(viewModel.status.type == StatusType.loading
                  ? [const LoadingView()]
                  : [
                      SocialLoginButton(
                        label: AppStrings.continueWithApple,
                        iconAsset: AppImages.authAppleIcon,
                        onPressed: () {
                          loginViewModel.signInWithApple();
                        },
                      ),
                      const SizedBox(height: 10),
                      SocialLoginButton(
                        label: AppStrings.continueWithGoogle,
                        iconAsset: AppImages.authGoogleIcon,
                        onPressed: () {
                          loginViewModel.signInWithGoogle();
                        },
                      ),
                    ]),

              const SizedBox(height: 10),
              Row(
                children: [
                  //colors have to be changes
                  Expanded(
                      child: Divider(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(AppStrings.or,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                  ),
                  Expanded(
                      child: Divider(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryAction,
                  disabledForegroundColor:
                      Theme.of(context).disabledColor,
                ),
                onPressed: isLoading
                    ? null
                    : () {
                        isLogin
                            ? navigator.replaceWith(AppRoutes.login)
                            : navigator.replaceWith(AppRoutes.register);
                      },
                child: const Text(AppStrings.continueWithEmail),
              ),
            ],
          ),
        ),
      );
    });
  }
}
