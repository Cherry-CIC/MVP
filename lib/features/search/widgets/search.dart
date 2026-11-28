import 'dart:async';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:cherry_mvp/features/search/charity_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Hint shown in every search entry point.
const String searchHint = 'Find something special...';

/// Both shop entry points use the same search route and lifecycle.
///
/// With [initialCategory], search opens already scoped to that category and
/// leaves the keyboard closed so the results are visible straight away.
Future<void> openSearch(BuildContext context, {Category? initialCategory}) async {
  final model = context.read<HomeViewModel>();
  model.loadRecentSearches();
  if (initialCategory != null) {
    unawaited(model.selectSearchCategory(initialCategory));
  }
  await Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => SearchPage(autofocus: initialCategory == null)),
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
    final borderRadius = BorderRadius.circular(10);
    return Semantics(
      button: true,
      label: searchHint,
      excludeSemantics: true,
      onTap: () => openSearch(context),
      child: Material(
        color: colours.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: colours.outlineVariant),
        ),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () => openSearch(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: colours.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    searchHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colours.onSurfaceVariant,
                    ),
                  ),
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
  final bool autofocus;

  const SearchPage({this.autofocus = true, super.key});

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
      if (!mounted) return;
      context.read<HomeViewModel>().loadRecentSearches();
      // Charities from the backend are optional extras: if they fail to load,
      // search still finds every charity in the Discover catalogue.
      final charities = context.read<CharityViewModel?>();
      if (charities != null) unawaited(charities.ensureCharitiesLoaded());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _selectRecentSearch(String term) {
    _controller.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    _focusNode.unfocus();
    context.read<HomeViewModel>().submitSearch(term);
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<HomeViewModel>();
    final colours = Theme.of(context).colorScheme;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: colours.outlineVariant),
    );
    return Scaffold(
      backgroundColor: colours.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 16, 8),
              child: Row(
                children: [
                  const BackButton(),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: widget.autofocus,
                      maxLength: 100,
                      textInputAction: TextInputAction.search,
                      onChanged: model.updateSearchText,
                      onSubmitted: (value) {
                        _focusNode.unfocus();
                        model.submitSearch(value);
                      },
                      onTapOutside: (_) => _focusNode.unfocus(),
                      decoration: InputDecoration(
                        hintText: searchHint,
                        counterText: '',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 38),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _controller,
                          builder: (context, value, _) => value.text.isEmpty
                              ? const SizedBox.shrink()
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _controller.clear();
                                    model.updateSearchText('');
                                  },
                                ),
                        ),
                        filled: true,
                        fillColor: colours.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
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
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: InputChip(
                    label: Text(model.searchCategory!.name),
                    deleteButtonTooltipMessage: 'Clear category',
                    onDeleted: () => model.selectSearchCategory(null),
                  ),
                ),
              ),
            Expanded(
              child: _SearchBody(
                onRecentSearchSelected: _selectRecentSearch,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({required this.onRecentSearchSelected});
  final ValueChanged<String> onRecentSearchSelected;

  void _openCharity(BuildContext context, CharitySearchResult charity) {
    FocusManager.instance.primaryFocus?.unfocus();
    final homeModel = context.read<HomeViewModel>();
    if (homeModel.searchText.isNotEmpty) {
      unawaited(homeModel.recordRecentSearch(homeModel.searchText));
    }
    unawaited(NavigationProvider.openCharityProfileFromContext(context, charity.profileArgs));
  }

  void _openProduct(BuildContext context, Product product) {
    FocusManager.instance.primaryFocus?.unfocus();
    final homeModel = context.read<HomeViewModel>();
    if (homeModel.searchText.isNotEmpty) {
      unawaited(homeModel.recordRecentSearch(homeModel.searchText));
    }
    context.read<ProductViewModel>().goToProductPage(product);
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return ProductCard(
      key: ValueKey(product.id),
      product: product,
      onTap: () => _openProduct(context, product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<HomeViewModel>();
    final browsing = !model.hasActiveSearch;

    // Charities are matched by name as the user types. They are left out when
    // a category is selected, because categories only contain items.
    final charitySearch =
        context.read<CharitySearch?>() ??
        CharitySearch(
          discoverRepository: context.read<DiscoverRepository?>() ?? DiscoverRepository(),
        );
    final apiCharities = context.watch<CharityViewModel?>()?.charities ?? const <Charity>[];
    final charities = (!browsing && model.searchCategory == null)
        ? charitySearch.search(model.searchText, apiCharities: apiCharities)
        : const <CharitySearchResult>[];

    Widget content;
    if (browsing) {
      final recentSearches = model.recentSearches;
      if (recentSearches.isEmpty) {
        content = const SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptySearchPrompt(),
        );
      } else {
        content = SliverList.list(
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Recent searches',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: model.clearRecentSearches,
                  child: const Text('Clear all'),
                ),
              ],
            ),
            for (final term in recentSearches)
              _RecentSearchRow(
                term: term,
                onTap: () => onRecentSearchSelected(term),
                onRemove: () => model.removeRecentSearch(term),
              ),
          ],
        );
      }
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
          message: charities.isNotEmpty
              ? null
              : (model.searchCategory == null ? 'Try different words.' : 'Try different words or clear the category.'),
        ),
      );
    } else {
      final products = model.searchProducts;
      final rowCount = (products.length / 2).ceil();
      content = SliverList.builder(
        itemCount: rowCount + 1,
        itemBuilder: (context, index) {
          if (index < rowCount) {
            final firstIndex = index * 2;
            final secondIndex = firstIndex + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildProductCard(context, products[firstIndex])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: secondIndex < products.length
                        ? _buildProductCard(context, products[secondIndex])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              if (products.isEmpty && model.searchHasMore)
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
    if (charities.isNotEmpty) {
      content = SliverMainAxisGroup(
        slivers: [
          const SliverToBoxAdapter(child: _SectionHeader('Charities')),
          SliverList.list(
            children: [
              for (final charity in charities)
                _CharityResultTile(
                  charity: charity,
                  onTap: () => _openCharity(context, charity),
                ),
            ],
          ),
          const SliverToBoxAdapter(child: _SectionHeader('Items')),
          content,
        ],
      );
    }
    return Stack(
      children: [
        if (model.isSearchEmpty && charities.isEmpty && Theme.of(context).brightness == Brightness.light)
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset('assets/images/search/empty_background.png', fit: BoxFit.cover),
            ),
          ),
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth == 0 &&
                notification.metrics.axis == Axis.vertical &&
                notification.metrics.extentAfter < 600 &&
                model.hasActiveSearch &&
                model.searchProducts.isNotEmpty &&
                model.searchHasMore &&
                !model.isSearchLoading &&
                !model.isLoadingMoreSearch &&
                model.searchLoadMoreError == null) {
              unawaited(model.loadMoreSearchProducts());
            }
            return false;
          },
          child: CustomScrollView(
            key: ValueKey('${model.searchCategory?.id}/${model.searchText}'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [SliverPadding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 24), sliver: content)],
          ),
        ),
      ],
    );
  }
}

class _EmptySearchPrompt extends StatelessWidget {
  const _EmptySearchPrompt();

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colours.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search, size: 32, color: colours.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Search for anything',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Find pre-loved items and charities across Cherry.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: colours.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  const _RecentSearchRow({
    required this.term,
    required this.onTap,
    required this.onRemove,
  });

  final String term;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colours.outlineVariant)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 4),
        leading: Icon(Icons.history, size: 20, color: colours.onSurfaceVariant),
        title: Text(term, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          tooltip: 'Remove recent search',
          icon: Icon(Icons.close, size: 18, color: colours.onSurfaceVariant),
          onPressed: onRemove,
        ),
        onTap: onTap,
      ),
    );
  }
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _CharityResultTile extends StatelessWidget {
  const _CharityResultTile({required this.charity, required this.onTap});
  final CharitySearchResult charity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;
    final fallbackIcon = Icon(
      Icons.volunteer_activism_outlined,
      size: 24,
      color: charity.usesDarkLogoBackground ? Colors.white70 : Colors.black54,
    );
    final logoPath = charity.logoPath;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: onTap,
      leading: ExcludeSemantics(
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: charity.usesDarkLogoBackground ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: colours.outlineVariant),
          ),
          child: logoPath == null
              ? fallbackIcon
              : ImageProviderHelper.buildImage(
                  imagePath: logoPath,
                  fit: BoxFit.contain,
                  errorWidget: fallbackIcon,
                ),
        ),
      ),
      title: Text(charity.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: const Text('Charity'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
