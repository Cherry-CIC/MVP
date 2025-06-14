import 'package:cherry_mvp/core/config/app_images.dart';
import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:cherry_mvp/core/models/user_section.dart';
import 'package:cherry_mvp/core/reusablewidgets/image_carousel.dart';
import 'package:cherry_mvp/features/home/home_model.dart';
import 'package:cherry_mvp/features/products/product_information.dart';
import 'package:cherry_mvp/features/products/seller_information.dart';
import 'package:flutter/material.dart';

class ProductPage extends StatelessWidget {
  final String productId;

  const ProductPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: BackButton(
            color: Colors.white,
          ),
          expandedHeight: MediaQuery.of(context).size.width -
              MediaQuery.of(context).padding.top,
          flexibleSpace: FlexibleSpaceBar(
            background: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ImageCarousel(images: [
                        AssetImage(AppImages.product1),
                        AssetImage(AppImages.product2),
                        AssetImage(AppImages.product3),
                      ]),
                    ),
                    PositionedDirectional(
                      end: 24,
                      bottom: 16,
                      child: Material(
                        color: Colors.white54,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            spacing: 4,
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              Text(
                                '3',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )),
          ),
        ),
        SliverList.list(children: [
          SellerInformation(
            user: UserInformation(
              username: 'John Doe',
              location: 'New York, USA',
              reviewsCount: 120,
              followersCount: 300,
              followingCount: 150,
              rating: 3.5,
              awards: 37,
              hasBuyerDiscounts: true,
            ),
            charity: Image.asset(AppImages.homeStart),
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
          ),
          Divider(thickness: 8),
          ProductInformation(
            product: dummyProducts.first,
            padding: EdgeInsets.all(16),
          ),
          Divider(thickness: 8),
          ListTile(
            title: Text(AppStrings.productPageDescription),
            titleTextStyle: Theme.of(context).textTheme.titleSmall,
            subtitle: Text(dummyProducts.first.description),
            subtitleTextStyle:
                TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          Divider(thickness: 8),
          ShadedTile(
            onTap: () {},
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                spacing: 16,
                children: [
                  Expanded(
                      child: Text(
                    AppStrings.productPageBuyerDiscountActive,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary),
                  )),
                  Expanded(
                    child: Text(
                      AppStrings.productPageBuy2Get1HalfPrice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        shape: BoxShape.circle),
                    child: Icon(Icons.arrow_forward,
                        color: Theme.of(context).colorScheme.onTertiary),
                  ),
                ],
              ),
            ),
          ),
          ShadedTile(
            onTap: () {},
            child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  spacing: 16,
                  children: [
                    Expanded(
                        child: Text(
                      AppStrings.productPageOpenToOtherCharities,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary),
                    )),
                    Expanded(
                      child: Text(
                        AppStrings.productPageRequestOtherCharity,
                        style: Theme.of(context)
                            .primaryTextTheme
                            .bodySmall
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    Container(
                      alignment: Alignment.center,
                      height: 32,
                      width: 32,
                      child: Image.asset(
                        AppImages.sale,
                        height: 24,
                        width: 24,
                      ),
                    ),
                  ],
                )),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              spacing: 16,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: OutlinedButton(
                        onPressed: () {},
                        child: Text(AppStrings.productPageMakeOffer)),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: FilledButton(
                        onPressed: () {},
                        child: Text(AppStrings.productPageBuyNow)),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ]),
      ],
    ));
  }
}

class ShadedTile extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onTap;

  const ShadedTile({super.key, this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.fromLTRB(0, 8, 16, 8),
      child: Material(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        type: MaterialType.button,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).colorScheme.primaryContainer,
                ],
                begin: Alignment.centerLeft,
                end: Alignment(2, .5),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
