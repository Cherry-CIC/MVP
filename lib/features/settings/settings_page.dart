import 'package:flutter/material.dart';   
 
import 'package:cherry_mvp/core/config/config.dart'; 
import 'package:cherry_mvp/features/settings/widgets/toggle_section.dart';
import 'package:cherry_mvp/features/settings/widgets/support_section.dart';
import 'package:cherry_mvp/features/settings/widgets/personal_section.dart';
import 'package:cherry_mvp/features/settings/widgets/shop_section.dart';
import 'package:cherry_mvp/features/settings/widgets/account_section.dart';
import 'package:cherry_mvp/features/settings/widgets/footer.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});  

  @override
  SettingsPageState createState() => SettingsPageState();
}

 

class SettingsPageState extends State<SettingsPage> { 

  @override 
  Widget build(BuildContext context) {     

    return Scaffold( 
      backgroundColor: Colors.white,  

      appBar: AppBar( 
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: Icon(
            Icons.reply, 
            color: AppColors.primary,  
          ),
          onPressed: () {},
        ), 
  
        title: Text(
          "Settings",
          style: TextStyle(fontSize:15, color: AppColors.black, fontWeight: FontWeight.w800,), 
        ),     
 
        centerTitle: true,   
        
      ), 

      body:DecoratedBox(  
        decoration: BoxDecoration( 
          //   
        ),
        child: SingleChildScrollView( 
          child: Column( 
            children: <Widget>[  

              Padding(
                padding: const EdgeInsets.only(top: 0.0, right:15.0, left:15.0),  
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 

                  children: [  
                    ToggleSection(), 

                    SupportSection(), 

                    PersonalSection(), 

                    ShopSection(), 

                    AccountSection(), 

                    Footer(), 
                  ]
                ),
              ),

            ],
          ),
        ),
      ), 
    ); 
  } 
}
