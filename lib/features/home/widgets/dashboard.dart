import 'package:cherry_mvp/features/home/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/home/home_viewmodel.dart';
import 'package:provider/provider.dart';

import 'category.dart';
 
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
        body: Consumer<HomeViewModel>(
        builder: (context, viewModel, _) {
      final products = viewModel.fetchProducts();
      final categories = viewModel.fetchCategories();

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    "Just For You",
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Image.asset(
                    AppImages.icButton,
                    width: 30,
                    height: 30,
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 0.7),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return SingleProduct(product: products[index]);
                },
              ),
              SizedBox(height: 30),
              Row(
                children: [
                  Text(
                    "Categories",
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Image.asset(
                    AppImages.icButton,
                    width: 30,
                    height: 30,
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 0.8),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return SingleCategory(category: categories[index]);
                },
              ),
            ],
          ),
        ),
      );
        },
        ),
    );
  }
}