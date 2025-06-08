import 'package:flutter/material.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/reusablewidgets/reusablewidgets.dart';  

class ToggleItem extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool)? onChanged;

  const ToggleItem({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical:10.0, horizontal:15.0),
      margin: EdgeInsets.only(bottom:20.0),
      decoration: BoxDecoration(
        color: AppColors.lightGreyFill, 
        borderRadius: BorderRadius.circular(50.0),
      ), 
 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.toggleSwitch,
          ),

          CustomToggleSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ]
      ) 
    );
  }
}