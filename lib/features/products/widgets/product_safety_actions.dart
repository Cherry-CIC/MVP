import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter/material.dart';

enum ProductSafetyMenuAction {
  reportProduct,
  reportSeller,
  blockSeller,
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

Future<ReportDraft?> showReportProductSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<ReportDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _ReportSheet(title: title),
  );
}

Future<bool> showBlockSellerDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(AppStrings.productPageBlockSellerTitle),
      content: const Text(AppStrings.productPageBlockSellerMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.productPageCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.productPageBlockSellerConfirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.title});

  final String title;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedReason;

  static const List<_ReportReason> _reasons = [
    _ReportReason('misleading_listing', 'Misleading listing'),
    _ReportReason('prohibited_item', 'Prohibited item'),
    _ReportReason('harassment_or_abuse', 'Harassment or abuse'),
    _ReportReason('scam_or_fraud', 'Scam or fraud'),
    _ReportReason('other', 'Other'),
  ];

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
              for (final reason in _reasons)
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

class _ReportReason {
  const _ReportReason(this.value, this.label);

  final String value;
  final String label;
}
