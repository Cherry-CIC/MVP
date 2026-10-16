import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/discover/discover_repository.dart';
import 'package:flutter/material.dart';

class CharityDetailsDialog extends StatelessWidget {
  const CharityDetailsDialog({super.key, required this.charity});

  final Charity charity;

  @override
  Widget build(BuildContext context) {
    final suppliedDescription = charity.description?.trim();
    final description = suppliedDescription != null && suppliedDescription.isNotEmpty
        ? suppliedDescription
        : DiscoverRepository().descriptionForCharityName(charity.name);
    return Dialog(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: SizedBox.square(dimension: 96, child: CharityLogo(charity: charity)),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      header: true,
                      child: Text(
                        charity.name.trim().isEmpty ? 'Charity' : charity.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description == null || description.isEmpty
                          ? 'A description is not available for this charity yet.'
                          : description,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CharityLogo extends StatelessWidget {
  const CharityLogo({super.key, required this.charity});

  final Charity charity;

  @override
  Widget build(BuildContext context) {
    const fallback = Center(child: Icon(Icons.volunteer_activism, color: Colors.grey));
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: charity.imageUrl.trim().isEmpty
            ? fallback
            : Image(
                image: ImageProviderHelper.getImageProvider(charity.imageUrl.trim()),
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
