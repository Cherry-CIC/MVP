import 'dart:io';

import 'package:cherry_mvp/core/models/category.dart';
import 'package:cherry_mvp/core/models/product.dart';
import 'package:cherry_mvp/core/router/router.dart';
import 'package:cherry_mvp/features/donation/models/donation_form_model.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_dropdown_field.dart';
import 'package:cherry_mvp/features/donation/widgets/donation_form_field.dart';
import 'package:cherry_mvp/features/donation/widgets/photo_upload.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'edit_listing_draft.dart';
import 'edit_listing_repository.dart';
import 'edit_listing_view_model.dart';

/// A non-null result also signals an uncertain PUT, so callers invalidate old
/// listing data even when the editor cannot confirm that a save succeeded.
class EditListingResult {
  const EditListingResult({this.product});
  final Product? product;
}

class EditListingPage extends StatelessWidget {
  const EditListingPage({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => EditListingViewModel(
      repository: context.read<IEditListingRepository>(),
      productId: productId,
    )..load(),
    child: const _EditListingScreen(),
  );
}

class _EditListingScreen extends StatefulWidget {
  const _EditListingScreen();
  @override
  State<_EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<_EditListingScreen> {
  bool _allowPop = false;
  bool _confirmingExit = false;

  Future<bool> _confirmDiscard(String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard your changes?'),
          content: const Text('Your unsaved changes will be lost.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
          ],
        ),
      ) ??
      false;

  Future<void> _close([Product? saved]) async {
    final vm = context.read<EditListingViewModel>();
    if (vm.isSaving || _confirmingExit) return;
    _confirmingExit = true;
    if (saved == null && vm.isDirty && !await _confirmDiscard('Discard changes')) {
      _confirmingExit = false;
      return;
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, vm.writeAttempted ? EditListingResult(product: saved) : null);
    });
  }

  Future<void> _reload() async {
    final vm = context.read<EditListingViewModel>();
    if (vm.isDirty && !await _confirmDiscard('Reload listing')) return;
    if (mounted) await vm.load();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditListingViewModel>();
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit listing'),
          leading: BackButton(onPressed: vm.isSaving ? null : () => _close()),
        ),
        body: SafeArea(
          child: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.original == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(vm.error ?? 'Could not load this listing', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        OutlinedButton(onPressed: vm.load, child: const Text('Try again')),
                      ],
                    ),
                  ),
                )
              : _EditListingForm(
                  key: ValueKey(vm.formVersion),
                  onSaved: _close,
                  onReload: _reload,
                ),
        ),
      ),
    );
  }
}

class _EditListingForm extends StatefulWidget {
  const _EditListingForm({super.key, required this.onSaved, required this.onReload});
  final Future<void> Function(Product) onSaved;
  final Future<void> Function() onReload;
  @override
  State<_EditListingForm> createState() => _EditListingFormState();
}

class _EditListingFormState extends State<_EditListingForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    final vm = context.read<EditListingViewModel>();
    _title = TextEditingController(text: vm.draft!.name);
    _description = TextEditingController(text: vm.draft!.description);
    _categoryName = vm.original!.category?.name;
    _title.addListener(() => vm.update(vm.draft!.copyWith(name: _title.text)));
    _description.addListener(() => vm.update(vm.draft!.copyWith(description: _description.text)));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final saved = await context.read<EditListingViewModel>().save();
    if (!mounted || saved == null) return;
    await widget.onSaved(saved);
  }

  Future<void> _selectCategory() async {
    final vm = context.read<EditListingViewModel>();
    final selected = await context.read<NavigationProvider>().navigateTo(
      AppRoutes.category,
      arguments: {'selectionMode': true, 'initialCategoryId': vm.draft!.categoryId},
    );
    if (!mounted || selected is! Category) return;
    setState(() => _categoryName = selected.name);
    vm.update(vm.draft!.copyWith(categoryId: selected.id));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditListingViewModel>();
    final draft = vm.draft!;
    final disabled = vm.isSaving || vm.requiresReload;
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Keep your listing accurate so people know what they are buying.'),
            ),
            // Disable keyboard focus as well as pointer input during persistence.
            ExcludeFocus(
              excluding: disabled,
              child: AbsorbPointer(
                absorbing: disabled,
                child: Column(
                  children: [
                    _ListingPhotos(
                      photos: draft.photos,
                      onChanged: (photos) => vm.update(draft.copyWith(photos: photos)),
                    ),
                    DonationFormField(
                      controller: _title,
                      title: 'Title',
                      hintText: titleHintText,
                      validator: EditListingDraft.validateTitle,
                    ),
                    DonationFormField(
                      controller: _description,
                      title: 'Description',
                      hintText: descriptionHintText,
                      minLines: 3,
                      validator: EditListingDraft.validateDescription,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: OutlinedButton(
                        onPressed: _selectCategory,
                        child: Row(
                          children: [
                            Expanded(child: Text('Category: ${_categoryName ?? 'Choose a category'}')),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                    DonationDropdownField(
                      formFieldsHintText: 'Condition',
                      dropdownList: {...qualityDropdownList, draft.quality}.toList(),
                      selectedValue: draft.quality,
                      onChanged: (value) {
                        if (value != null) vm.update(draft.copyWith(quality: value));
                      },
                    ),
                    DonationDropdownField(
                      formFieldsHintText: 'Size',
                      dropdownList: {...sizeDropdownList, draft.size}.toList(),
                      selectedValue: draft.size,
                      onChanged: (value) {
                        if (value != null) vm.update(draft.copyWith(size: value));
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Price, charity, postage and quantity cannot be changed here.'),
            ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ),
            if (vm.requiresReload)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(onPressed: widget.onReload, child: const Text('Reload listing')),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: vm.canSave ? _save : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: vm.isSaving
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 12),
                          Flexible(child: Text('Saving changes…')),
                          ],
                        )
                      : const Text('Save changes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingPhotos extends StatelessWidget {
  const _ListingPhotos({required this.photos, required this.onChanged});
  final List<ListingPhoto> photos;
  final ValueChanged<List<ListingPhoto>> onChanged;

  Future<void> _addPhotos(BuildContext context) async {
    List<XFile> selected = [];
    final added = await showModalBottomSheet<List<XFile>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(16), child: Text('Add photos')),
            Expanded(
              child: SingleChildScrollView(
                child: PhotoUpload(
                  onImagesChanged: (images) => selected = List.of(images),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('Use these photos'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || added == null || added.isEmpty) return;
    final existingPaths = photos.map((photo) => photo.file?.path).whereType<String>().toSet();
    onChanged([...photos, ...added.where((file) => existingPaths.add(file.path)).map(ListingPhoto.local)]);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Photos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text('Keep at least one photo. The first photo is your main listing photo.'),
        const SizedBox(height: 12),
        for (var index = 0; index < photos.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: photos[index].remoteUrl != null
                        ? Image.network(
                            photos[index].remoteUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                          )
                        : Image.file(
                            File(photos[index].file!.path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(index == 0 ? 'Main photo' : 'Photo ${index + 1}')),
                if (index > 0)
                  IconButton(
                    tooltip: 'Make photo ${index + 1} the main photo',
                    onPressed: () {
                      final updated = List.of(photos);
                      updated.insert(0, updated.removeAt(index));
                      onChanged(updated);
                    },
                    icon: const Icon(Icons.vertical_align_top),
                  ),
                IconButton(
                  tooltip: 'Remove photo ${index + 1}',
                  onPressed: () => onChanged(List.of(photos)..removeAt(index)),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _addPhotos(context),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Add photos'),
        ),
      ],
    ),
  );
}
