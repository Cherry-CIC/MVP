import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({super.key});

  static final _url = Uri.parse('https://cherry.org.uk/privacypolicy');

  Future<void> _open(BuildContext context) async {
    try {
      if (await launchUrl(_url, mode: LaunchMode.externalApplication)) return;
    } on PlatformException {
      // Some platforms throw instead of reporting a failed launch.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText('Please open $_url in your browser.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: ListTile(
        title: const Text(AppStrings.privacyPolicyText),
        trailing: const Icon(Icons.open_in_new),
        onTap: () => _open(context),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.privacyPolicyText)),
      body: const SafeArea(child: PrivacyPolicyLink()),
    );
  }
}
