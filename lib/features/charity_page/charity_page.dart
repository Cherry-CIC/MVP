import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/charity_page/charity_model.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'widgets/charity_card.dart';

class CharityPage extends StatefulWidget {
  const CharityPage({
    super.key,
    this.selectionMode = false,
    this.initialCharityId,
  });

  final bool selectionMode;
  final String? initialCharityId;

  @override
  CharityPageState createState() => CharityPageState();
}

class CharityPageState extends State<CharityPage> {
  bool _hasInitialized = false;
  String? get _initialId => widget.initialCharityId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      context.read<CharityViewModel>().fetchCharities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CharityViewModel>(
      builder: (context, viewModel, child) {
        final charities = viewModel.charities;
        final status = viewModel.status;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: ImageProviderHelper.buildImage(
                imagePath: AppImages.backCharity,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(AppStrings.charitiesText),
            centerTitle: true,
          ),
          body: Container(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    height: 40,
                    child: SearchAnchor.bar(
                      barHintText: AppStrings.searchCharities,
                      isFullScreen: true,
                      barBackgroundColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.secondaryContainer,
                      ),
                      barElevation: WidgetStateProperty.all(0),
                      barShape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: AppColors.borderGrey,
                            width: 1,
                          ),
                        ),
                      ),
                      suggestionsBuilder: (context, controller) => [],
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.only(top: 8)),
                Expanded(
                  child: _buildCharityList(viewModel, status, charities),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleCharityTap(Charity charity) {
    if (widget.selectionMode) {
      Navigator.of(context).pop(charity);
    }
  }

  Widget _buildCharityList(
      CharityViewModel viewModel,
      Status status,
      List<Charity> charities,
      ) {
    // Show loading widget when fetching data
    if (status.type == StatusType.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error widget if failed
    if (status.type == StatusType.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${AppStrings.charityError}: ${status.message}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.fetchCharities(),
              child: Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    // Show charities list when data is loaded
    if (charities.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        itemCount: charities.length,
        itemBuilder: (context, index) {
          final charity = charities[index];
          final isSelected = widget.selectionMode && charity.id == _initialId;
          return InkWell(
            onTap: () => _handleCharityTap(charity),
            child: Stack(
              children: [
                CharityCard(charity: charity),
                if (isSelected)
                  Positioned(
                    right: 0,
                    top: 4,
                    child: Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    // Show empty state if no charities
    return Center(child: Text(AppStrings.noCharitiesAvailable));
  }
}