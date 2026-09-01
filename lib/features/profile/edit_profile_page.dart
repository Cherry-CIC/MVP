import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/auth/auth_view_model.dart';
import 'package:cherry_mvp/features/profile/edit_profile_view_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;

  String _initialFirstName = '';
  String _initialUsername = '';
  String _initialPhone = '';

  @override
  void initState() {
    super.initState();
    final credentials = context.read<AuthViewModel>().userCredentials;

    _initialFirstName = credentials?.firstname?.trim() ?? '';
    _initialUsername = credentials?.username?.trim() ?? '';
    _initialPhone = credentials?.phoneNumber?.trim() ?? '';

    _firstNameController = TextEditingController(text: _initialFirstName);
    _usernameController = TextEditingController(text: _initialUsername);
    _phoneController = TextEditingController(text: _initialPhone);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String? _validateOptionalFirstName(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    return validateFirstName(value);
  }

  String? _validateOptionalPhone(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    return validatePhoneNumber(value);
  }

  /// Returns the trimmed value when it is non-empty and differs from the
  /// initial value, otherwise null (meaning "do not update this field").
  String? _changedValue(String current, String initial) {
    final trimmed = current.trim();
    if (trimmed.isEmpty || trimmed == initial) return null;
    return trimmed;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthViewModel>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    final firstName = _changedValue(_firstNameController.text, _initialFirstName);
    final username = _changedValue(_usernameController.text, _initialUsername);
    final phoneNumber = _changedValue(_phoneController.text, _initialPhone);

    final navigator = context.read<NavigationProvider>();

    if (firstName == null && username == null && phoneNumber == null) {
      navigator.goBack();
      return;
    }

    final result = await context.read<EditProfileViewModel>().saveProfile(
      uid: uid,
      firstName: firstName,
      username: username,
      phoneNumber: phoneNumber,
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? AppStrings.editProfileSaveFailed)),
      );
      return;
    }

    await auth.loadCurrentUser();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.editProfileSaveSuccess)),
    );
    navigator.goBack();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthViewModel, String?>(
      (auth) => auth.userCredentials?.email,
    );
    final photoUrl = context.select<AuthViewModel, String?>(
      (auth) => auth.userCredentials?.photoUrl,
    );
    final isSaving = context.watch<EditProfileViewModel>().isSaving;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(AppStrings.editProfileTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : AssetImage(AppImages.profileProfileIcon) as ImageProvider,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _firstNameController,
                  enabled: !isSaving,
                  textCapitalization: TextCapitalization.words,
                  validator: _validateOptionalFirstName,
                  decoration: const InputDecoration(
                    labelText: AppStrings.editProfileFirstNameLabel,
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  enabled: !isSaving,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return null;
                    return validateUsername(value);
                  },
                  decoration: const InputDecoration(
                    labelText: AppStrings.editProfileUsernameLabel,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  enabled: !isSaving,
                  keyboardType: TextInputType.phone,
                  validator: _validateOptionalPhone,
                  decoration: const InputDecoration(
                    labelText: AppStrings.editProfilePhoneLabel,
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  enabled: false,
                  initialValue: email ?? '',
                  decoration: const InputDecoration(
                    labelText: AppStrings.email,
                    prefixIcon: Icon(Icons.email_outlined),
                    helperText: AppStrings.editProfileEmailHelper,
                  ),
                ),
                const SizedBox(height: 32),
                // TODO: Change to BottomCTA when merged
                SizedBox(
                  height: 56,
                  child: isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton(
                          onPressed: _save,
                          child: const Text(AppStrings.editProfileSave),
                        ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
