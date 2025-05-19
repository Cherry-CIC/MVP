import 'package:flutter/material.dart';
import 'package:cherry_mvp/features/search/searched_product_desc_page/ad_example.dart';

class SearchedProductDescPage extends StatefulWidget {
  const SearchedProductDescPage({super.key});

  @override
  SearchedProductDescPageState createState() => SearchedProductDescPageState();
}

class SearchedProductDescPageState extends State<SearchedProductDescPage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: AdExample()
    );
  }
}