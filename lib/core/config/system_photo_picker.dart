import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Configures [ImagePicker] to use the out-of-process system photo picker
/// (`PickVisualMedia` / `PickMultipleVisualMedia`) on Android rather than
/// legacy broad-storage intents.
void configureSystemPhotoPicker([ImagePickerPlatform? platform]) {
  final instance = platform ?? ImagePickerPlatform.instance;
  if (instance is ImagePickerAndroid) {
    instance.useAndroidPhotoPicker = true;
  }
}
