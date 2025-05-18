import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/models/model.dart';

class MyCartPage extends StatelessWidget {
  const MyCartPage({super.key});

  final List<Product> cartItems = const [
    Product(
      name: "Charity Hoodie",
      price: 24.99,
      number: 1,
      likes: 120,
      product_image: "assets/images/mens_t_shirt.png",
      charity_image: "assets/images/shoes_4.png",
    ),
    Product(
      name: "Support T-Shirt",
      price: 14.99,
      number: 2,
      likes: 85,
      product_image: "assets/images/shoes_4.png",
      charity_image: "assets/images/charity_logo.png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double total = cartItems.fold(
      0,
      (sum, item) => sum + item.price,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Image.asset(item.product_image, width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(item.name),
                      subtitle: Text("£${item.price.toStringAsFixed(2)}"),
                      trailing: Text("x${item.number}"),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
                Text("£${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Checkout (Mock)"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Use Stripe test card:"),
                        SizedBox(height: 6),
                        Text("Card: 4242 4242 4242 4242"),
                        Text("Exp: 12/34"),
                        Text("CVC: 123"),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✅ Payment successful (mock)!"),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        },
                        child: const Text("Confirm"),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,  
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Checkout"),
            ),
          ],
        ),
      ),
    );
  }
}
