import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

/// Both shop entry points use the same search route and lifecycle.
Future<void> openSearch(BuildContext context) async {
  final model = context.read<HomeViewModel>();
  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const SearchPage()),
  );
  model.clearSearch();
}

class Search extends StatelessWidget {
  final bool showAsBar;

  const Search({this.showAsBar = false, super.key});

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    if (!showAsBar) {
      return Image.asset(AppImages.icSearch, width: 24, height: 24, color: colours.secondary);
    }
    return Semantics(
      button: true,
      label: 'Search items',
      excludeSemantics: true,
      onTap: () => openSearch(context),
      child: Material(
        color: colours.surfaceContainerHighest,
        elevation: 1,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => openSearch(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: colours.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Search items', style: TextStyle(color: colours.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.text = context.read<HomeViewModel>().searchText;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoryViewModel>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<HomeViewModel>();
    final colours = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colours.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
              child: Row(
                children: [
                  const BackButton(),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      maxLength: 100,
                      textInputAction: TextInputAction.search,
                      onChanged: model.updateSearchText,
                      onSubmitted: (_) {
                        _focusNode.unfocus();
                        model.retrySearch();
                      },
                      onTapOutside: (_) => _focusNode.unfocus(),
                      decoration: InputDecoration(
                        hintText: 'Search items',
                        counterText: '',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _controller,
                          builder: (context, value, _) => value.text.isEmpty
                              ? const SizedBox.shrink()
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    _controller.clear();
                                    model.updateSearchText('');
                                  },
                                ),
                        ),
                        filled: true,
                        fillColor: colours.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(color: colours.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide(color: colours.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (model.searchCategory != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: InputChip(
                    label: Text(model.searchCategory!.name),
                    deleteButtonTooltipMessage: 'Clear category',
                    onDeleted: () => model.selectSearchCategory(null),
                  ),
                ),
              ),
            Expanded(
              child: _SearchBody(
                onCategorySelected: (category) {
                  _focusNode.unfocus();
                  model.selectSearchCategory(category);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.onCategorySelected});
  final ValueChanged<Category> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final model = context.watch<HomeViewModel>();
    final categories = context.watch<CategoryViewModel>();
    final browsing = !model.hasActiveSearch;
    Widget content;
    if (browsing) {
      content = SliverList.list(
        children: [
          _BrowseRow(
            label: 'Charities',
            icon: SvgPicture.asset('assets/images/search/charities.svg', width: 25, height: 25),
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              context.read<NavigationProvider>().navigateTo(AppRoutes.discover);
            },
          ),
          if (categories.status.type == StatusType.loading || categories.status.type == StatusType.uninitialized)
            const _SearchLoading(label: 'Loading categories')
          else if (categories.status.type == StatusType.failure)
            _SearchMessage(
              title: 'Could not load categories',
              message: 'You can still search for items above.',
              action: TextButton(onPressed: categories.fetchCategories, child: const Text('Retry categories')),
            )
          else if (categories.categories.isEmpty)
            const _SearchMessage(title: 'No categories available', message: 'Search for an item above.')
          else
            for (final category in categories.categories)
              _BrowseRow(
                label: category.name,
                icon: Image.network(
                  category.imageUrl,
                  width: 25,
                  height: 25,
                  color: Theme.of(context).colorScheme.primary,
                  errorBuilder: (_, error, stack) => Image.asset(
                    AppImages.getCategoryIcon(category.name),
                    width: 25,
                    height: 25,
                    color: Theme.of(context).colorScheme.primary,
                    errorBuilder: (_, error, stack) => const Icon(Icons.category_outlined),
                  ),
                ),
                onTap: () => onCategorySelected(category),
              ),
        ],
      );
    } else if (model.isSearchLoading) {
      content = const SliverToBoxAdapter(child: _SearchLoading(label: 'Searching items'));
    } else if (model.searchStatus.type == StatusType.failure) {
      content = SliverToBoxAdapter(
        child: _SearchMessage(
          title: 'Search failed',
          message: 'Please try again.',
          action: TextButton(onPressed: model.retrySearch, child: const Text('Retry search')),
        ),
      );
    } else if (model.isSearchEmpty) {
      content = SliverToBoxAdapter(
        child: _SearchMessage(
          title: 'No items found',
          message: model.searchCategory == null ? 'Try different words.' : 'Try different words or clear the category.',
        ),
      );
    } else {
      content = SliverList.builder(
        itemCount: model.searchProducts.length + 1,
        itemBuilder: (context, index) {
          if (index < model.searchProducts.length) return _ProductSuggestionTile(product: model.searchProducts[index]);
          return Column(
            children: [
              if (model.searchProducts.isEmpty && model.searchHasMore)
                const _SearchMessage(title: 'Keep looking', message: 'More listings are available to check.'),
              if (model.searchLoadMoreError != null) _SearchMessage(title: model.searchLoadMoreError!),
              if (model.isLoadingMoreSearch)
                const _SearchLoading(label: 'Loading more items')
              else if (model.searchHasMore)
                TextButton(
                  onPressed: model.loadMoreSearchProducts,
                  child: const Text('Load more results'),
                ),
            ],
          );
        },
      );
    }
    return Stack(
      children: [
        if (model.isSearchEmpty && Theme.of(context).brightness == Brightness.light)
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset('assets/images/search/empty_background.png', fit: BoxFit.cover),
            ),
          ),
        CustomScrollView(
          key: ValueKey('${model.searchCategory?.id}/${model.searchText}'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), sliver: content)],
        ),
      ],
    );
  }
}

class _BrowseRow extends StatelessWidget {
  const _BrowseRow({required this.label, required this.icon, required this.onTap});
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
    ),
    child: ListTile(
      minTileHeight: 60,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: ExcludeSemantics(child: icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, size: 24),
      onTap: onTap,
    ),
  );
}

class _SearchLoading extends StatelessWidget {
  const _SearchLoading({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: label,
    child: const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.title, this.message, this.action});
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
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

class _ProductSuggestionTile extends StatelessWidget {
  const _ProductSuggestionTile({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.productImages.firstOrNull;
    return ListTile(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        context.read<ProductViewModel>().goToProductPage(product);
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: imageUrl == null
            ? const SizedBox(width: 48, height: 48, child: Icon(Icons.image_not_supported_outlined))
            : Image.network(
                imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) =>
                    const SizedBox(width: 48, height: 48, child: Icon(Icons.image_not_supported_outlined)),
              ),
      ),
      title: Text(product.name),
      subtitle: Text('${product.quality} · ${product.size}'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
