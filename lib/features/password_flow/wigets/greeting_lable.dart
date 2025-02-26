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
    return Text(
      "Hello $name !!",
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
