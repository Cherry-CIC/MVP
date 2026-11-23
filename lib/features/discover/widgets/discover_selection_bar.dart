import 'package:flutter/material.dart';

import 'package:cherry_mvp/core/config/feature_flags.dart';

class DiscoverSelectionBar extends StatelessWidget {
  const DiscoverSelectionBar({
    required this.selectedTag,
    required this.onSelected,
    super.key,
  });

  static const String popularTag = 'popular';
  static const String categoriesTag = 'categories';

  final String selectedTag;
  final ValueChanged<String> onSelected;

  static const _tabs = [
    ('Popular', popularTag),
    ('Smaller Charities', 'smaller-charities'),
    ('Local to you', 'local'),
    ('Categories', categoriesTag),
  ];

  static List<(String, String)> get _visibleTabs => _tabs
      .where((tab) => tab.$2 != 'local' || FeatureFlags.showLocalCharitiesTab)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Row(
          children: _visibleTabs
              .map(
                (tab) => _TabButton(
                  label: tab.$1,
                  semanticsLabel: tab.$2 == categoriesTag ? tab.$1 : '${tab.$1} charities',
                  isSelected: selectedTag == tab.$2,
                  onTap: () => onSelected(tab.$2),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.semanticsLabel,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colourScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        excludeSemantics: true,
        label: semanticsLabel,
        onTap: onTap,
        child: Material(
          color: isSelected ? colourScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          elevation: isSelected ? 2 : 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isSelected ? colourScheme.primary : colourScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
