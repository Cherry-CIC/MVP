import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/charity_page/charity_viewmodel.dart';

import 'widgets/charity_card.dart';

import 'package:cherry_mvp/features/charity_page/charity_model.dart';

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
    return Consumer<CharityViewModel>(builder: (context, viewModel, child) {
      final charities = viewModel.charities;
      final status = viewModel.status;

      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.reply,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(AppStrings.charitiesText),
          centerTitle: true,
        ),
        body: Container(
            padding: const EdgeInsets.only(top: 5),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  height: 40,
                  child: SearchAnchor.bar(
                      barHintText: AppStrings.searchCharities,
                      isFullScreen: true,
                      suggestionsBuilder: (context, controller) => []),
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 8)),
              Expanded(
                child: _buildCharityList(viewModel, status, charities),
              ),
            ])),
      );
    });
  }

  void _handleCharityTap(Charity charity) {
    if (widget.selectionMode) {
      Navigator.of(context).pop(charity);
    }
  }

  Widget _buildCharityList(
      CharityViewModel viewModel, Status status, List<Charity> charities) {
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
        itemCount: charities.length,
        itemBuilder: (context, index) {
          final charity = charities[index];
          final isSelected =
              widget.selectionMode && charity.id == _initialId;
          return InkWell(
            onTap: () => _handleCharityTap(charity),
            child: Stack(
              children: [
                CharityCard(charity: charity),
                if (isSelected)
                  Positioned(
                    right: 16,
                    top: 16,
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
