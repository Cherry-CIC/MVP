import 'package:flutter/cupertino.dart';

class AppMeasurements {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double appWidth(BuildContext context) {
    return getScreenWidth(context) - 40;
  }
}