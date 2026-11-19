import 'package:cherry_mvp/core/config/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('giveInStyle tagline is formatted with proper title case and exclamation mark', () {
    expect(AppStrings.giveInStyle, 'Give in Style!');
  });
}
