import 'package:cherry_mvp/features/charity_page/charity_model.dart';

/// Route payload used to open a [CharityProfilePage] from any charity touchpoint.
class CharityProfileArgs {
  const CharityProfileArgs({
    this.charity,
    this.charityId,
    this.charityName,
    this.charityImageUrl,
  });

  final Charity? charity;
  final String? charityId;
  final String? charityName;
  final String? charityImageUrl;

  /// Validates and normalises arbitrary route arguments for [CharityProfilePage].
  static CharityProfileArgs? fromRouteArgument(Object? argument) {
    if (argument is CharityProfileArgs) {
      return _validate(argument);
    }
    if (argument is Charity) {
      return _validate(
        CharityProfileArgs(
          charity: argument,
          charityId: argument.id,
          charityName: argument.name,
          charityImageUrl: argument.imageUrl,
        ),
      );
    }
    if (argument is String) {
      final id = safeIdentifier(argument);
      return id == null ? null : CharityProfileArgs(charityId: id);
    }
    if (argument is Map) {
      final charity = argument['charity'] is Charity
          ? argument['charity'] as Charity
          : null;
      final charityId = argument['charityId'] is String
          ? argument['charityId'] as String
          : charity?.id;
      final charityName = argument['charityName'] is String
          ? argument['charityName'] as String
          : charity?.name;
      final charityImageUrl = argument['charityImageUrl'] is String
          ? argument['charityImageUrl'] as String
          : charity?.imageUrl;
      return _validate(
        CharityProfileArgs(
          charity: charity,
          charityId: charityId,
          charityName: charityName,
          charityImageUrl: charityImageUrl,
        ),
      );
    }
    return null;
  }

  static String? safeIdentifier(String? charityId) {
    final value = charityId?.trim();
    if (value == null ||
        value.isEmpty ||
        value == '.' ||
        value == '..' ||
        RegExp(r'[/\\\x00-\x1f\x7f]').hasMatch(value)) {
      return null;
    }
    return value;
  }

  static CharityProfileArgs? _validate(CharityProfileArgs args) {
    final id = safeIdentifier(args.charityId ?? args.charity?.id);
    final name = (args.charityName ?? args.charity?.name ?? '').trim();
    final imageUrl = (args.charityImageUrl ?? args.charity?.imageUrl ?? '')
        .trim();

    if (id == null && name.isEmpty) {
      return null;
    }

    return CharityProfileArgs(
      charity: args.charity,
      charityId: id,
      charityName: name.isEmpty ? null : name,
      charityImageUrl: imageUrl.isEmpty ? null : imageUrl,
    );
  }
}
