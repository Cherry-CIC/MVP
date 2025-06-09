import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'product_model.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  final _nameController = TextEditingController();
  final _qualityController = TextEditingController();
  final _priceController = TextEditingController();
  final _charityController = TextEditingController();
  final _likesController = TextEditingController();
  final _numberController = TextEditingController();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = picked);
    }
  }

  Future<void> _saveProduct() async {
    if (_selectedImage == null ||
        _nameController.text.isEmpty ||
        _qualityController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _charityController.text.isEmpty ||
        _likesController.text.isEmpty ||
        _numberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields and pick an image!')),
      );
      return;
    }

    final product = Product(
      name: _nameController.text,
      quality: _qualityController.text,
      imagePath: _selectedImage!.path,
      price: double.tryParse(_priceController.text) ?? 0,
      charity: _charityController.text,
      likes: int.tryParse(_likesController.text) ?? 0,
      number: int.tryParse(_numberController.text) ?? 0,
    );
    await ProductDatabase.instance.insertProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product saved!')),
    );
    setState(() {
      _selectedImage = null;
      _nameController.clear();
      _qualityController.clear();
      _priceController.clear();
      _charityController.clear();
      _likesController.clear();
      _numberController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _selectedImage == null
                  ? Container(
                      height: 150,
                      width: 150,
                      color: Colors.grey[300],
                      child: const Icon(Icons.add_a_photo, size: 50),
                    )
                  : Image.file(File(_selectedImage!.path),
                      height: 150, width: 150, fit: BoxFit.cover),
            ),
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
                controller: _qualityController,
                decoration: const InputDecoration(labelText: 'Quality')),
            TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number),
            TextField(
                controller: _charityController,
                decoration: const InputDecoration(labelText: 'Charity')),
            TextField(
                controller: _likesController,
                decoration: const InputDecoration(labelText: 'Likes'),
                keyboardType: TextInputType.number),
            TextField(
                controller: _numberController,
                decoration: const InputDecoration(labelText: 'Number'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _saveProduct, child: const Text('Save Product')),
          ],
        ),
      ),
    );
  }
}

class ProductDatabase {
  static final ProductDatabase instance = ProductDatabase._internal();

  ProductDatabase._internal();

  Future<void> insertProduct(Product product) async {
    // TODO: Implement database insert logic here
  }
}
