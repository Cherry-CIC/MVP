import 'dart:async';

import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/products/delete_listing_view_model.dart';
import 'package:cherry_mvp/features/profile/profile_listings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<DeleteListingOutcome?> showDeleteListingDialog(
  BuildContext context, {
  required DeleteListingViewModel viewModel,
  required String productId,
  required String ownerId,
  required bool knownSold,
  required ListingActionSession actionSession,
  VoidCallback? onNotOwner,
}) => showDialog<DeleteListingOutcome>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _DeleteListingDialog(
    viewModel: viewModel,
    productId: productId,
    ownerId: ownerId,
    knownSold: knownSold,
    actionSession: actionSession,
    onNotOwner: onNotOwner,
  ),
);

/// Capture shared state before awaiting: removing a card can dispose its context.
Future<void> requestListingDeletion(
  BuildContext context, {
  required String productId,
  required String ownerId,
  required bool knownSold,
  required ListingActionSession actionSession,
  VoidCallback? onRemoved,
  VoidCallback? onRefreshDetails,
}) async {
  final vm = context.read<DeleteListingViewModel>();
  if (!vm.isCurrent(actionSession) || !vm.canDelete(productId, ownerId: ownerId, knownSold: knownSold)) return;
  final messenger = ScaffoldMessenger.of(context);
  final navigation = context.read<NavigationProvider>();
  final profile = context.read<ProfileListingsViewModel>();
  final home = context.read<HomeViewModel>();
  final outcome = await showDeleteListingDialog(
    context,
    viewModel: vm,
    productId: productId,
    ownerId: ownerId,
    knownSold: knownSold,
    actionSession: actionSession,
    onNotOwner: () {
      if (!vm.isCurrent(actionSession)) return;
      onRefreshDetails?.call();
      unawaited(profile.refreshListings());
    },
  );
  if (outcome == null || !vm.isCurrent(actionSession)) return;
  if (outcome.removed) {
    onRemoved?.call();
    if (messenger.mounted) messenger.showSnackBar(SnackBar(content: Text(outcome.message)));
    unawaited(Future.wait([profile.refreshListings(), home.refreshAfterListingDeletion()]));
  } else if (outcome == DeleteListingOutcome.unauthenticated) {
    await navigation.navigateTo(AppRoutes.login);
  }
}

class _DeleteListingDialog extends StatefulWidget {
  const _DeleteListingDialog({
    required this.viewModel,
    required this.productId,
    required this.ownerId,
    required this.knownSold,
    required this.actionSession,
    this.onNotOwner,
  });
  final DeleteListingViewModel viewModel;
  final String productId;
  final String ownerId;
  final bool knownSold;
  final ListingActionSession actionSession;
  final VoidCallback? onNotOwner;

  @override
  State<_DeleteListingDialog> createState() => _DeleteListingDialogState();
}

class _DeleteListingDialogState extends State<_DeleteListingDialog> {
  bool _busy = false;
  DeleteListingOutcome? _outcome;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final outcome = await widget.viewModel.delete(
      widget.productId,
      ownerId: widget.ownerId,
      knownSold: widget.knownSold,
      actionSession: widget.actionSession,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _outcome = outcome;
    });
    if (outcome == DeleteListingOutcome.notOwner) widget.onNotOwner?.call();
    if (outcome.removed) Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final current = widget.viewModel.isCurrent(widget.actionSession);
      final outcome = current ? _outcome : DeleteListingOutcome.accountChanged;
      final colours = Theme.of(context).colorScheme;
      return PopScope(
        canPop: !_busy,
        child: AlertDialog(
          scrollable: true,
          title: const Text('Delete this listing?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This will remove your listing from cherry. You cannot undo this action.'),
              if (outcome != null) ...[
                const SizedBox(height: 16),
                Semantics(liveRegion: true, child: Text(outcome.message)),
              ],
              if (_busy) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator(semanticsLabel: 'Deleting listing')),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: _busy
                  ? null
                  : () => Navigator.pop(context, outcome == DeleteListingOutcome.notOwner ? outcome : null),
              child: Text(outcome == null ? 'Cancel' : 'Close'),
            ),
            if (outcome == DeleteListingOutcome.unauthenticated)
              FilledButton(
                onPressed: () => Navigator.pop(context, outcome),
                child: const Text('Sign in'),
              )
            else if (current && (outcome == null || outcome.canRetry))
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: colours.error, foregroundColor: colours.onError),
                onPressed: _busy ? null : _submit,
                child: Text(outcome == null ? 'Delete listing' : 'Try again'),
              ),
          ],
        ),
      );
    },
  );
}
