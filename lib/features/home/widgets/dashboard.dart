import 'package:cherry_mvp/core/router/nav_provider.dart';
import 'package:cherry_mvp/core/router/nav_routes.dart';
import 'package:cherry_mvp/features/categories/category_view_model.dart';
import 'package:cherry_mvp/features/products/product_card.dart';
import 'package:cherry_mvp/features/products/product_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard_loading_widget.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard_error_widget.dart';
import 'package:cherry_mvp/features/home/widgets/dashboard_empty_widget.dart';
import 'package:cherry_mvp/core/utils/utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialized) {
      _hasInitialized = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categoryVM = context.read<CategoryViewModel>();
        final homeVM = context.read<HomeViewModel>();

        categoryVM.fetchCategories();
        homeVM.fetchProducts();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, homeViewModel, _) {
        final navigator = Provider.of<NavigationProvider>(
          context,
          listen: false,
        );
        final productViewModel = Provider.of<ProductViewModel>(
          context,
          listen: false,
        );
        final products = homeViewModel.products;
        final status = homeViewModel.status;

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Show loading widget when fetching data
              if (status.type == StatusType.loading)
                const DashboardLoadingWidget()
              // Show error widget if failed
              else if (status.type == StatusType.failure)
                DashboardErrorWidget(
                  errorMessage: status.message,
                  onRetry: () => homeViewModel.fetchProducts(),
                )
              // Show products grid when data is loaded
              else if (products.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.61,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        productViewModel.setProduct(products[index]);
                        navigator.navigateTo(AppRoutes.product);
                      },
                      child: ProductCard(product: products[index]),
                    );
                  },
                )
              // Show empty state if no products
              else
                const DashboardEmptyWidget(),
            ],
          ),
        );
      },
    );
  }
}
