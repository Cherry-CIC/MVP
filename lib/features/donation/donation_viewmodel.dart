import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/features/categories/category_repository.dart';
import 'package:cherry_mvp/features/donation/models/donation_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DonationViewModel extends ChangeNotifier {
  final CategoryRepository categoryRepository;

  var busy = false;
  final _images = <XFile>[];
  var _isSwitchedOpenToOtherCharity = false;
  var _isSwitchedOpenToOffer = false;
  var _isSwitchedApplicableBuyerDiscounts = false;
  double? price;
  String? condition;
  Category? category;

  DonationViewModel({required this.categoryRepository});

  bool get isSwitchedOpenToOtherCharity => _isSwitchedOpenToOtherCharity;
  set isSwitchedOpenToOtherCharity(bool value) {
    _isSwitchedOpenToOtherCharity = value;
    notifyListeners();
  }

  bool get isSwitchedOpenToOffer => _isSwitchedOpenToOffer;
  set isSwitchedOpenToOffer(bool value) {
    _isSwitchedOpenToOffer = value;
    notifyListeners();
  }

  bool get isSwitchedApplicableBuyerDiscounts =>
      _isSwitchedApplicableBuyerDiscounts;
  set isSwitchedApplicableBuyerDiscounts(bool value) {
    _isSwitchedApplicableBuyerDiscounts = value;
    notifyListeners();
  }

  List<XFile> get images => _images;
  void addImage(XFile image) {
    _images.add(image);
    notifyListeners();
  }

  void removeImage(XFile image) {
    _images.remove(image);
    notifyListeners();
  }

  List<Category> get categories => categoryRepository.fetchCategories()
    ..sort((a, b) => a.name.compareTo(b.name));

  List<String> get conditions => [
        "Condition A",
        "Condition B",
        "Condition C",
        "Condition D",
      ];

  Future<void> submitDonation(DonationRequest request) async {
    notifyListeners();
  }
}
