import 'package:flutter/material.dart';

enum ListingMenuAction { edit, delete }

/// Kept separate from the card's tap target so both actions are accessible.
class ListingActionsMenu extends StatelessWidget {
  const ListingActionsMenu({
    super.key,
    required this.listingName,
    this.onEdit,
    this.onDelete,
    this.busy = false,
  });

  final String listingName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (onEdit == null && onDelete == null) return const SizedBox.shrink();
    final colours = Theme.of(context).colorScheme;
    return Material(
      color: colours.surface,
      shape: const CircleBorder(),
      elevation: 1,
      child: SizedBox.square(
        dimension: 48,
        child: PopupMenuButton<ListingMenuAction>(
          tooltip: 'Manage $listingName',
          enabled: !busy,
          icon: busy
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.more_vert, color: colours.onSurface),
          onSelected: (action) {
            switch (action) {
              case ListingMenuAction.edit:
                onEdit?.call();
              case ListingMenuAction.delete:
                onDelete?.call();
            }
          },
          itemBuilder: (_) => [
            if (onEdit != null) const PopupMenuItem(value: ListingMenuAction.edit, child: Text('Edit listing')),
            if (onDelete != null)
              PopupMenuItem(
                value: ListingMenuAction.delete,
                child: Text('Delete listing', style: TextStyle(color: colours.error)),
              ),
          ],
        ),
      ),
    );
  }
}
