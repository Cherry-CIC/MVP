import 'package:cherry_mvp/core/models/product.dart';
import 'package:flutter/foundation.dart';
import 'edit_listing_draft.dart';
import 'edit_listing_repository.dart';

class EditListingViewModel extends ChangeNotifier {
  EditListingViewModel({required this.repository, required this.productId});
  final IEditListingRepository repository;
  final String productId;

  Product? original;
  EditListingDraft? draft;
  bool isLoading = false;
  bool isSaving = false;
  bool requiresReload = false;
  bool writeAttempted = false;
  String? error;
  int formVersion = 0;
  bool _disposed = false;

  bool get isDirty => original != null && draft != null && draft!.hasChanges(original!);
  bool get canSave => !isLoading && !isSaving && !requiresReload && isDirty;

  Future<void> load() async {
    if (isLoading || isSaving) return;
    isLoading = true;
    error = null;
    _notify();
    try {
      final result = await repository.load(productId);
      if (_disposed) return;
      if (result.isSuccess && result.value != null) {
        original = result.value;
        draft = EditListingDraft.fromProduct(original!);
        formVersion++;
        requiresReload = false;
      } else {
        error = result.error ?? 'Could not load this listing';
        if (original != null) requiresReload = true;
      }
    } catch (_) {
      error = 'Could not load this listing. Please try again.';
      if (original != null) requiresReload = true;
    } finally {
      isLoading = false;
      _notify();
    }
  }

  void update(EditListingDraft value) {
    if (isLoading || isSaving || requiresReload) return;
    draft = value;
    error = null;
    _notify();
  }

  Future<Product?> save() async {
    if (!canSave) return null;
    final validationError = draft!.validate(original!);
    if (validationError != null) {
      error = validationError;
      _notify();
      return null;
    }
    isSaving = true;
    error = null;
    _notify();
    try {
      final result = await repository.save(original!, draft!);
      writeAttempted = writeAttempted || result.writeAttempted;
      requiresReload = result.requiresReload;
      error = result.error;
      if (result.isSuccess) {
        original = result.product;
        draft = EditListingDraft.fromProduct(original!);
        return result.product;
      }
      return null;
    } catch (_) {
      // A custom repository may have thrown after sending the request.
      requiresReload = true;
      writeAttempted = true;
      error = 'We could not confirm the save. Reload the listing to check its current details.';
      return null;
    } finally {
      isSaving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
