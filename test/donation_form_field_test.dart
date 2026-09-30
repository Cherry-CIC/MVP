import 'package:cherry_mvp/features/donation/widgets/donation_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('title and description retain numbers and punctuation and pass validation', (tester) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    addTearDown(titleController.dispose);
    addTearDown(descriptionController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: Column(
              children: [
                DonationFormField(
                  controller: titleController,
                  title: 'Title',
                  hintText: 'Enter a title',
                ),
                DonationFormField(
                  controller: descriptionController,
                  title: 'Description',
                  hintText: 'Enter a description',
                  minLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('This cannot be empty'), findsNWidgets(2));

    const title = 'route 66 shirt!';
    const description = 'Women’s "Route 66" T-shirt, size 10/12 & 100% cotton.\nCafé print: £5.50 👕';
    await tester.enterText(find.byType(TextFormField).at(0), title);
    await tester.enterText(find.byType(TextFormField).at(1), description);

    expect(titleController.text, title);
    expect(descriptionController.text, description);
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(find.text('This cannot be empty'), findsNothing);
    expect(find.text('This can only contain letters and spaces'), findsNothing);
  });
}
