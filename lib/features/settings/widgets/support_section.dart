import 'package:flutter/material.dart';   
import 'package:cherry_mvp/features/settings/settings_model.dart'; 
import 'package:cherry_mvp/features/settings/widgets/settings_list.dart';


class SupportSection extends StatelessWidget {
  const SupportSection({super.key});  

  @override 
  Widget build(BuildContext context) {     

    return Container( 
      child: SettingsList(item: dummySettingsItems[0]),
    ); 
  } 
}
