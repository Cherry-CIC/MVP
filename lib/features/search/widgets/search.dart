import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Search extends StatefulWidget {
  final bool showAsBar;

  const Search({this.showAsBar = false, super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  SearchController? _searchController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final controller = context.read<SearchController>();
    if (_searchController == controller) {
      return;
    }

    _searchController?.removeListener(_onSearchTextChanged);
    _searchController = controller;
    _searchController?.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController?.removeListener(_onSearchTextChanged);
    super.dispose();
  }

  void _onSearchTextChanged() {
    final query = _searchController?.text ?? '';
    context.read<HomeViewModel>().updateSearchText(query);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, homeViewModel, _) {
        return SearchAnchor(
          searchController: context.read<SearchController>(),
          viewHintText: 'AI Search: Red Polka Dot Dress',
          viewBackgroundColor: Theme.of(context).colorScheme.surface,
          viewOnClose: () {
            final controller = _searchController;
            if (controller != null && controller.text.isNotEmpty) {
              controller.clear();
            }
            context.read<HomeViewModel>().clearSearch();
          },
          suggestionsBuilder: (context, controller) {
            final query = controller.text.trim();
            return [
              _SearchSuggestions(query: query),
            ];
          },
          builder: (context, controller) {
            final activeQuery = homeViewModel.searchText;
            final label = activeQuery.isEmpty ? 'AI Search: Red Polka Dot Dress' : activeQuery;

            if (!widget.showAsBar) {
              return Image.asset(
                AppImages.icSearch,
                width: 24,
                height: 24,
                color: Theme.of(context).colorScheme.secondary,
              );
            }

            return Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              elevation: 1,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: controller.openView,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      if (activeQuery.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () {
                            controller.clear();
                            context.read<HomeViewModel>().clearSearch();
                          },
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  final String query;

  const _SearchSuggestions({required this.query});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, homeViewModel, _) {
        final products = query.isEmpty ? const <Product>[] : homeViewModel.searchProducts;
        final isWaitingForSearch = query.isNotEmpty && homeViewModel.isSearchLoading;

        if (isWaitingForSearch) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (query.isNotEmpty && homeViewModel.searchStatus.type == StatusType.failure) {
          return ListTile(
            leading: const Icon(Icons.error_outline),
            title: const Text('Search failed'),
            subtitle: Text(homeViewModel.searchStatus.message ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => homeViewModel.updateSearchText(query),
            ),
          );
        }

        if (query.isNotEmpty && homeViewModel.isSearchEmpty) {
          return ListTile(
            leading: const Icon(Icons.search_off),
            title: Text('No products found for "$query"'),
          );
        }

        final suggestions = products.map<Widget>((product) => _ProductSuggestionTile(product: product)).toList();

        if (homeViewModel.isLoadingMoreSearch) {
          suggestions.add(
            const ListTile(
              title: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (homeViewModel.searchHasMore) {
          suggestions.add(
            ListTile(
              leading: const Icon(Icons.more_horiz),
              title: const Text('Load more results'),
              onTap: homeViewModel.loadMoreSearchProducts,
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: suggestions,
        );
      },
    );
  }
}

class _ProductSuggestionTile extends StatelessWidget {
  final Product product;

  const _ProductSuggestionTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.productImages.isNotEmpty ? product.productImages.first : null;

    return ListTile(
      onTap: () {
        context.read<ProductViewModel>().goToProductPage(product);
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: imageUrl == null
            ? Container(
                width: 40,
                height: 40,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image_not_supported_outlined, size: 20),
              )
            : Image.network(
                imageUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 40,
                  height: 40,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image, color: AppColors.red),
                ),
              ),
      ),
      title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${product.quality} · ${product.size}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
