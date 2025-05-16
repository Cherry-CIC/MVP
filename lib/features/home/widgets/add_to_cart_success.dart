import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/models/model.dart';

class AddToCartSuccessPage extends StatelessWidget {
  final Product product;

  const AddToCartSuccessPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Success')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 20),
              Text('${product.name} added to cart!', style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 10),
              Text('Price: £${product.price.toStringAsFixed(2)}'),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
