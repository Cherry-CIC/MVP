import 'dart:io';

import 'package:flutter/material.dart';   

import 'package:cherry_mvp/core/config/config.dart'; 
import 'package:cherry_mvp/core/models/model.dart';  
import 'package:cherry_mvp/features/settings/widgets/settings_item.dart';



class SettingsList extends StatelessWidget {
  const SettingsList({super.key, required this.item,});

  final SectionSettings item;  

  @override
  Widget build(BuildContext context) {   
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [   
        SizedBox( 
          height: 15, 
        ), 

        Container( 
          child: Text( 
            item.header,
            style: TextStyle(fontSize: 17, color: AppColors.black, fontWeight: FontWeight.w800,),
          ),
        ), 
 
        ...item.list_items.map((singleItem) => SettingsItem(item: singleItem)).toList(),
        
      ]
    );  
  }
}
