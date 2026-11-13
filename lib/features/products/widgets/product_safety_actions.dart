import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';

enum ProductSafetyMenuAction {
  reportProduct,
  reportSeller,
  blockSeller,
}

/// Actions offered in the triple-dot menu on [CharityProfilePage].
enum CharitySafetyMenuAction {
  reportCharity,
  blockCharity,
}

class ReportReasonOption {
  const ReportReasonOption(this.value, this.label);

  final String value;
  final String label;
}

class ReportDraft {
  const ReportDraft({
    required this.reason,
    this.message,
  });

  final String reason;
  final String? message;
}

class ProductSafetyActionsButton extends StatelessWidget {
  const ProductSafetyActionsButton({
    super.key,
    required this.onSelected,
    this.iconColor = Colors.white,
  });

  final ValueChanged<ProductSafetyMenuAction> onSelected;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ProductSafetyMenuAction>(
      tooltip: AppStrings.productPageMoreActions,
      icon: Icon(Icons.more_vert, color: iconColor),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ProductSafetyMenuAction.reportProduct,
          child: _ProductSafetyMenuItem(
            icon: Icons.flag_outlined,
            label: AppStrings.productPageReportProduct,
          ),
        ),
        PopupMenuItem(
          value: ProductSafetyMenuAction.reportSeller,
          child: _ProductSafetyMenuItem(
            icon: Icons.person_off_outlined,
            label: AppStrings.productPageReportSeller,
          ),
        ),
        PopupMenuItem(
          value: ProductSafetyMenuAction.blockSeller,
          child: _ProductSafetyMenuItem(
            icon: Icons.block,
            label: AppStrings.productPageBlockSeller,
          ),
        ),
      ],
    );
  }
}

/// Overflow safety menu used on a charity's profile header.
class CharitySafetyActionsButton extends StatelessWidget {
  const CharitySafetyActionsButton({
    super.key,
    required this.onSelected,
    this.iconColor,
  });

  final ValueChanged<CharitySafetyMenuAction> onSelected;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CharitySafetyMenuAction>(
      tooltip: AppStrings.productPageMoreActions,
      icon: Icon(
        Icons.more_vert,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: CharitySafetyMenuAction.reportCharity,
          child: _ProductSafetyMenuItem(
            icon: Icons.flag_outlined,
            label: AppStrings.reportCharityMenuLabel,
          ),
        ),
        PopupMenuItem(
          value: CharitySafetyMenuAction.blockCharity,
          child: _ProductSafetyMenuItem(
            icon: Icons.block,
            label: AppStrings.blockCharityMenuLabel,
          ),
        ),
      ],
    );
  }
}

class _ProductSafetyMenuItem extends StatelessWidget {
  const _ProductSafetyMenuItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

const List<ReportReasonOption> defaultProductReportReasons = [
  ReportReasonOption('misleading_listing', 'Misleading listing'),
  ReportReasonOption('prohibited_item', 'Prohibited item'),
  ReportReasonOption('harassment_or_abuse', 'Harassment or abuse'),
  ReportReasonOption('scam_or_fraud', 'Scam or fraud'),
  ReportReasonOption('other', 'Other'),
];

const List<ReportReasonOption> charityReportReasons = [
  ReportReasonOption('misleading_information', 'Misleading information'),
  ReportReasonOption('inappropriate_content', 'Inappropriate content'),
  ReportReasonOption('scam_or_fraud', 'Scam or fraud'),
  ReportReasonOption('harassment_or_abuse', 'Harassment or abuse'),
  ReportReasonOption('other', 'Other'),
];

Future<ReportDraft?> showReportProductSheet(
  BuildContext context, {
  required String title,
  List<ReportReasonOption> reasons = defaultProductReportReasons,
}) {
  return showModalBottomSheet<ReportDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _ReportSheet(title: title, reasons: reasons),
  );
}

/// Shared confirmation dialog preventing accidental report or block actions.
Future<bool> showSafetyConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.productPageCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> showBlockSellerDialog(BuildContext context) {
  return showSafetyConfirmationDialog(
    context,
    title: AppStrings.productPageBlockSellerTitle,
    message: AppStrings.productPageBlockSellerMessage,
    confirmLabel: AppStrings.productPageBlockSellerConfirm,
  );
}

/// Prompts the user to confirm before opening the report charity form.
Future<bool> showReportCharityConfirmationDialog(BuildContext context) {
  return showSafetyConfirmationDialog(
    context,
    title: AppStrings.reportCharityConfirmTitle,
    message: AppStrings.reportCharityConfirmBody,
    confirmLabel: AppStrings.reportCharityConfirmAction,
  );
}

/// Prompts the user to confirm before blocking a charity.
Future<bool> showBlockCharityDialog(BuildContext context) {
  return showSafetyConfirmationDialog(
    context,
    title: AppStrings.blockCharityConfirmTitle,
    message: AppStrings.blockCharityConfirmBody,
    confirmLabel: AppStrings.blockCharityConfirmAction,
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.title,
    required this.reasons,
  });

  final String title;
  final List<ReportReasonOption> reasons;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedReason;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.productPageReportReasonPrompt,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final reason in widget.reasons)
                        ChoiceChip(
                          label: Text(reason.label),
                          selected: _selectedReason == reason.value,
                          onSelected: (_) {
                            setState(() {
                              _selectedReason = reason.value;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _messageController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: AppStrings.productPageReportMessageLabel,
                      hintText: AppStrings.productPageReportMessageHint,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (bottomInset > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => FocusScope.of(context).unfocus(),
                child: const Text(AppStrings.productPageReportKeyboardDone),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedReason == null ? null : _submit,
              child: const Text(AppStrings.productPageReportSubmit),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final reason = _selectedReason;
    if (reason == null) {
      return;
    }
    Navigator.of(context).pop(
      ReportDraft(
        reason: reason,
        message: _messageController.text.trim(),
      ),
    );
  }
}
