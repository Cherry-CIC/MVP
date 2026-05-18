import 'package:cherry_mvp/features/checkout/constants/address_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/features/checkout/checkout_view_model.dart';

class PickupPointSelectionPage extends StatefulWidget {
  const PickupPointSelectionPage({super.key});

  @override
  State<PickupPointSelectionPage> createState() => _PickupPointSelectionPageState();
}

class _PickupPointSelectionPageState extends State<PickupPointSelectionPage> {
  var postcodeEntered = false;
  final TextEditingController postcodeController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  @override
  void initState() {
    super.initState();

    countryController.text = 'GB';
  }

  @override
  Widget build(BuildContext context) {
    // TODO need to look at layout, especially on mobile
    final viewModel = context.read<CheckoutViewModel>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(100),
          child: Column(
            children: (!postcodeEntered)
                ? [
                    Text(
                      AppStrings.address,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.postCode,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 175,
                              child: TextField(
                                controller: postcodeController,
                                keyboardType: TextInputType.streetAddress,
                                decoration: InputDecoration(
                                  hintText: AddressConstants.postCodeHintText,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.countryText,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 175,
                              child: TextField(
                                enabled: false,
                                controller: countryController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => postcodeController.text.isEmpty ? null : setState(() => postcodeEntered = true),
                      child: Text(AppStrings.checkoutFindNearestPickupPoints),
                    ),
                  ]
                : [
                    // TODO map view with markers for InPost locker locations
                    FilledButton(
                      onPressed: () async {
                        await viewModel.fetchNearestInposts(postcodeController.text, countryController.text);
                        // TODO set the first returned as selected for now
                        final hasValidInposts = viewModel.nearestInposts.isNotEmpty;
                        if (hasValidInposts) {
                          viewModel.setSelectedInpost(viewModel.nearestInposts.first);
                        }
                        viewModel.goBack(hasValidInposts);
                      },
                      child: Text('map view select first'),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
