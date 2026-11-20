import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/utils/status.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The catalogue categories shown under Discover's Categories tab.
class DiscoverCategoriesList extends StatelessWidget {
  const DiscoverCategoriesList({required this.onCategorySelected, super.key});

  final ValueChanged<Category> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryViewModel>();
    final statusType = categories.status.type;
    final items = categories.categories;

    if (statusType == StatusType.loading || statusType == StatusType.uninitialized) {
      return SliverToBoxAdapter(
        child: Semantics(
          liveRegion: true,
          label: 'Loading categories',
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    if (statusType == StatusType.failure) {
      return SliverToBoxAdapter(
        child: _Message(
          title: 'Could not load categories',
          message: 'You can still search for items above.',
          action: TextButton(
            onPressed: categories.fetchCategories,
            child: const Text('Retry categories'),
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const SliverToBoxAdapter(
        child: _Message(title: 'No categories available', message: 'Search for an item above.'),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList.list(
        children: [
          for (final category in items)
            _CategoryRow(category: category, onTap: () => onCategorySelected(category)),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colours.outline))),
      child: ListTile(
        minTileHeight: 60,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: ExcludeSemantics(
          child: Image.network(
            category.imageUrl,
            width: 25,
            height: 25,
            color: colours.primary,
            errorBuilder: (_, error, stack) => Image.asset(
              AppImages.getCategoryIcon(category.name),
              width: 25,
              height: 25,
              color: colours.primary,
              errorBuilder: (_, error, stack) => const Icon(Icons.category_outlined),
            ),
          ),
        ),
        title: Text(category.name),
        trailing: const Icon(Icons.chevron_right, size: 24),
        onTap: onTap,
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.title, this.message, this.action});

  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, textAlign: TextAlign.center),
          ],
          ?action,
        ],
      ),
    ),
  );
}
