import 'dart:io';
 
import 'package:flutter/material.dart';   

import 'package:cherry_mvp/core/config/config.dart'; 
import 'package:cherry_mvp/core/models/model.dart';   
import 'package:cherry_mvp/features/settings/widgets/settings_item.dart';



class SingleCategory extends StatelessWidget {
  const SingleCategory({super.key, required this.list_items, required this.heading,});

  final List<SectionSettingsItem> list_items;
  final String heading; 

  @override
  Widget build(BuildContext context) {   
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [   
        Padding( 
          padding: const EdgeInsets.only(top: 15.0),
          child: Text( 
            heading,
            style: TextStyle(fontSize: 17, color: AppColors.black, fontWeight: FontWeight.w800,),
          ),
        ),  

        ...list_items.map((item) => SettingsItem(title: item.title, onTap: (){}, trailing: item.trailing)).toList(), 
 
      ]
    );  
  }
}
