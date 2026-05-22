import 'package:cherry_mvp/features/donation/donation_view_model.dart';
import 'package:cherry_mvp/features/donation/models/postage_size_info.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/core/utils/utils.dart';

// TODO needs styled
class PostageSizePage extends StatefulWidget {
  const PostageSizePage({
    super.key,
    this.initialPostageSize,
  });

  final PostageSize? initialPostageSize;

  @override
  PostageSizePageState createState() => PostageSizePageState();
}

class PostageSizePageState extends State<PostageSizePage> {
  bool _hasInitialized = false;
  PostageSize? get _initialPostageSize => widget.initialPostageSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _hasInitialized = true;
        context.read<DonationViewModel>().fetchPostageSizes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DonationViewModel>(
      builder: (context, viewModel, child) {
        final postageSizeInfos = viewModel.postageSizeInfos;
        final status = viewModel.status;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: ImageProviderHelper.buildImage(
                imagePath: AppImages.backIcon,
              ),
              onPressed: () => viewModel.goBack(),
            ),
            title: Text(AppStrings.postageSizesText),
            centerTitle: true,
          ),
          body: Container(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              children: [
                const Padding(padding: EdgeInsets.only(top: 8)),
                Expanded(
                  child: _buildPostageSizeInfosList(viewModel, status, postageSizeInfos),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostageSizeInfosList(
    DonationViewModel viewModel,
    Status status,
    List<PostageSizeInfo> postageSizeInfos,
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
            Text('${AppStrings.postageSizeInfoError}: ${status.message}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.fetchPostageSizes(),
              child: Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }
    debugPrint('post $postageSizeInfos');
    // Show charities list when data is loaded
    if (postageSizeInfos.isNotEmpty) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: postageSizeInfos.length,
        itemBuilder: (context, index) {
          final postageSizeInfo = postageSizeInfos[index];
          final isSelected = postageSizeInfo.size == _initialPostageSize;
          debugPrint('isselected ${postageSizeInfo.size} initial $_initialPostageSize');
          return InkWell(
            onTap: () => context.read<DonationViewModel>().goBack(
              PostageSize.values.firstWhere((size) => postageSizeInfo.size == size),
            ),
            child: Stack(
              children: [
                Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Size: ${postageSizeInfo.size.label}'),
                      Text('Desc: ${postageSizeInfo.description}'),
                    ],
                  ),
                ),
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
    return Center(child: Text(AppStrings.noPostageSizeInfosAvailable));
  }
}
