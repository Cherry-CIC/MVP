import 'package:flutter/material.dart';

class EmailActionPage extends StatelessWidget {
  const EmailActionPage({
    super.key,
    required this.title,
    required this.email,
    required this.message,
    required this.actions,
  });

  final String title;
  final String email;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.mark_email_unread_outlined, size: 36, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Semantics(header: true, child: Text(title, style: theme.textTheme.headlineMedium)),
                  const SizedBox(height: 8),
                  Text(email, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text(message, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
