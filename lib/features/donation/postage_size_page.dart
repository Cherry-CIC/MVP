import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/utils/image_provider_helper.dart';
import 'package:cherry_mvp/core/utils/utils.dart';
import 'package:cherry_mvp/features/donation/donation_view_model.dart';
import 'package:cherry_mvp/features/donation/models/postage_size_info.dart';

class PostageSizePage extends StatefulWidget {
  const PostageSizePage({
    super.key,
    this.initialPostageSize,
  });

  final PostageSizeInfo? initialPostageSize;

  @override
  PostageSizePageState createState() => PostageSizePageState();
}

class PostageSizePageState extends State<PostageSizePage> {
  bool _hasInitialized = false;
  PostageSizeInfo? get _initialPostageSize => widget.initialPostageSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
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
          body: SafeArea(
            child: _buildPostageSizeInfosList(viewModel, status, postageSizeInfos),
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
    if (status.type == StatusType.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status.type == StatusType.failure) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.postageSizeInfoError,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (status.message != null) ...[
              const SizedBox(height: 8),
              Text(
                status.message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => viewModel.fetchPostageSizes(),
              child: Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }

    if (postageSizeInfos.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: postageSizeInfos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final postageSizeInfo = postageSizeInfos[index];
          final isSelected = postageSizeInfo == _initialPostageSize;
          return _PostageSizeCard(
            postageSizeInfo: postageSizeInfo,
            isSelected: isSelected,
            onTap: () => context.read<DonationViewModel>().goBack(postageSizeInfo),
          );
        },
      );
    }

    return Center(child: Text(AppStrings.noPostageSizeInfosAvailable));
  }
}

class _PostageSizeCard extends StatelessWidget {
  const _PostageSizeCard({
    required this.postageSizeInfo,
    required this.isSelected,
    required this.onTap,
  });

  final PostageSizeInfo postageSizeInfo;
  final bool isSelected;
  final VoidCallback onTap;

  IconData get _icon {
    return switch (postageSizeInfo.size) {
      PostageSize.small => Icons.local_mall_outlined,
      PostageSize.medium => Icons.inventory_2_outlined,
      PostageSize.large => Icons.all_inbox_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected ? theme.colorScheme.primary : theme.colorScheme.outline;
    final iconBackground = isSelected ? theme.colorScheme.primary : theme.colorScheme.primaryContainer;
    final iconColour = isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icon, color: iconColour),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      postageSizeInfo.size.label,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      postageSizeInfo.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle : Icons.chevron_right,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
