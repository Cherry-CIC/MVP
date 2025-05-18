import 'package:cherry_mvp/core/config/app_text_styles.dart';
import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

class GreetingLabel extends StatefulWidget {
  final String initialName;

  const GreetingLabel({super.key, required this.initialName});

  @override
  _GreetingLableState createState() => _GreetingLableState();
}

class _GreetingLableState extends State<GreetingLabel> {
  late String name;

  @override
  void initState() {
    super.initState();
    name = widget.initialName; // Set initial name
  }

  void updateName(String newName) {
    setState(() {
      name = newName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text("${AppStrings.greeting} $name${AppStrings.exclamationMark}",
        style: AppTextStyles.heading1);
  }
}
