import 'package:flutter/material.dart';   
  
import 'package:cherry_mvp/core/config/config.dart';  
import 'package:cherry_mvp/features/settings/widgets/settings_account.dart'; 


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});   

  @override
  SettingsPageState createState() => SettingsPageState();
}

 

class SettingsPageState extends State<SettingsPage> {  

  @override 
  Widget build(BuildContext context) {     

    return Scaffold( 
      backgroundColor: AppColors.white,  

      body:DecoratedBox(  
        decoration: BoxDecoration( 
          //   
        ),
        child: SingleChildScrollView( 
          child: Column( 
            children: [  

              Padding(
                padding: const EdgeInsets.only(top: 0.0, right:15.0, left:15.0),  
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 

                  children: [    

                    SettingsAccount(),  
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
