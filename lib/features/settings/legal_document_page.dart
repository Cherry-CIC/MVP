import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.assetPath,
  });

  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(title),
            floating: true,
            snap: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<String>(
                future: DefaultAssetBundle.of(context).loadString(assetPath),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        AppStrings.legalDocumentLoadErrorText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return _LegalDocumentContent(
                    title: title,
                    text: snapshot.data!,
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalDocumentContent extends StatelessWidget {
  const _LegalDocumentContent({
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final blocks = _parseDocumentBlocks(title: title, source: text);
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final block in blocks) _DocumentBlockView(block: block),
        ],
      ),
    );
  }
}

enum _DocumentBlockType { title, metadata, heading, paragraph, bullet }

class _DocumentBlock {
  const _DocumentBlock({
    required this.type,
    required this.text,
    this.headingLevel = 0,
  });

  final _DocumentBlockType type;
  final String text;
  final int headingLevel;
}

class _DocumentBlockView extends StatelessWidget {
  const _DocumentBlockView({required this.block});

  final _DocumentBlock block;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colourScheme = Theme.of(context).colorScheme;

    switch (block.type) {
      case _DocumentBlockType.title:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            block.text,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colourScheme.onSurface,
            ),
          ),
        );
      case _DocumentBlockType.metadata:
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Text(
            block.text,
            style: textTheme.labelLarge?.copyWith(
              color: colourScheme.onSurfaceVariant,
            ),
          ),
        );
      case _DocumentBlockType.heading:
        return Padding(
          padding: EdgeInsets.only(
            top: block.headingLevel == 1 ? 20 : 14,
            bottom: 8,
          ),
          child: Text(
            block.text,
            style: _headingStyle(textTheme, colourScheme, block.headingLevel),
          ),
        );
      case _DocumentBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            block.text,
            style: textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: colourScheme.onSurface,
            ),
          ),
        );
      case _DocumentBlockType.bullet:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, right: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colourScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(dimension: 5),
                ),
              ),
              Expanded(
                child: Text(
                  block.text,
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: colourScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

TextStyle? _headingStyle(
  TextTheme textTheme,
  ColorScheme colourScheme,
  int headingLevel,
) {
  final baseStyle = headingLevel == 1
      ? textTheme.titleMedium
      : headingLevel == 2
      ? textTheme.titleSmall
      : textTheme.bodyLarge;

  return baseStyle?.copyWith(
    fontWeight: FontWeight.w600,
    color: colourScheme.onSurface,
    height: 1.3,
  );
}

List<_DocumentBlock> _parseDocumentBlocks({
  required String title,
  required String source,
}) {
  final blocks = <_DocumentBlock>[];
  final paragraphLines = <String>[];

  void flushParagraph() {
    final paragraph = paragraphLines.join('\n').trim();
    paragraphLines.clear();

    if (paragraph.isEmpty) {
      return;
    }

    if (blocks.isEmpty && _normaliseTitle(paragraph) == _normaliseTitle(title)) {
      blocks.add(_DocumentBlock(type: _DocumentBlockType.title, text: paragraph));
      return;
    }

    if (paragraph.startsWith('Date last updated:')) {
      blocks.add(_DocumentBlock(type: _DocumentBlockType.metadata, text: paragraph));
      return;
    }

    blocks.add(_DocumentBlock(type: _DocumentBlockType.paragraph, text: paragraph));
  }

  for (final rawLine in source.replaceAll('\r\n', '\n').split('\n')) {
    final line = rawLine.trim();

    if (line.isEmpty) {
      flushParagraph();
      continue;
    }

    if (_isNumberedHeading(line) || _isStandaloneHeading(line)) {
      flushParagraph();
      blocks.add(
        _DocumentBlock(
          type: _DocumentBlockType.heading,
          text: line,
          headingLevel: _headingLevel(line),
        ),
      );
      continue;
    }

    if (line.startsWith('- ')) {
      flushParagraph();
      blocks.add(
        _DocumentBlock(
          type: _DocumentBlockType.bullet,
          text: line.substring(2).trim(),
        ),
      );
      continue;
    }

    paragraphLines.add(line);
  }

  flushParagraph();
  return blocks;
}

String _normaliseTitle(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

bool _isNumberedHeading(String line) {
  return RegExp(r'^\d+(?:\.\d+)*\.?\s+\S').hasMatch(line);
}

bool _isStandaloneHeading(String line) {
  return line.endsWith(':') && line.length <= 80;
}

int _headingLevel(String line) {
  if (!_isNumberedHeading(line)) {
    return 2;
  }

  final number = line.split(RegExp(r'\s+')).first;
  return number.split('.').where((part) => part.isNotEmpty).length;
}
