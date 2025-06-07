import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/models/model.dart';  
 

class CharityCard extends StatefulWidget {
  const CharityCard({super.key, required this.charity,});
  final Charity charity;

  @override
  CharityCardState createState() => CharityCardState();
}

class CharityCardState extends State<CharityCard> {

  @override
  Widget build(BuildContext context) {  
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal:15),
              child: Row( 
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [  
                  Column(
                    children: [ 
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.asset(
                          widget.charity.charityImage,
                          height: 80,  
                          width: 80, 
                          fit: BoxFit.cover,
                        ),
                      ), 
                    ]
                  ),

                  Column( 
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.charity.charityName,
                        style: TextStyle(color: AppColors.black, fontSize:14, fontWeight: FontWeight.w700 )
                      ),

                      Container(
                        width: screenWidth-110,
                        child: Expanded(
                          child: Text(
                            widget.charity.description,
                            style: TextStyle(color: AppColors.greyTextColor, fontSize:12, ),
                            softWrap: true,
                          )
                        ),
                      ), 
 
                      Padding(
                        padding: EdgeInsets.only(right:10),
                        child: InkWell(
                          onTap: () {},
                          child: Text(
                            "See More",
                            style: TextStyle(color: AppColors.primary, fontSize:12, )
                          )
                        )
                      ),   
                    ]
                  ),
                ] 
              ),
            ),
 
          ]
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal:10),
          child: Divider()
        ),
      ]
    );
  }
}
