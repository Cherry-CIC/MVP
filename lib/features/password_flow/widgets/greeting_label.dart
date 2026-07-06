import 'package:cherry_mvp/core/config/config.dart';
import 'package:flutter/material.dart';

class GreetingLabel extends StatefulWidget {
  final String initialName;

  const GreetingLabel({super.key, required this.initialName});

  @override
  State<GreetingLabel> createState() => _GreetingLabelState();
}

class _GreetingLabelState extends State<GreetingLabel> {
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
        style: Theme.of(context).textTheme.headlineMedium);
  }
}

