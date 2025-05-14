import 'package:cherry_mvp/core/models/model.dart';

class SectionSettings {
  final String header;
  final List<SectionSettingsItem> list_items;  

  const SectionSettings(
      {required this.header, required this.list_items,});
}