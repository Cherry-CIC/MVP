import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cherry_mvp/core/config/config.dart';
import 'package:cherry_mvp/core/router/router.dart';

class SuccessfulUploadPage extends StatelessWidget {
  const SuccessfulUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.15),
                    ),
                    ExcludeSemantics(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: Card(
                          color: Theme.of(context).colorScheme.primary,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.surface,
                              width: 12,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                            child: Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.surface,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            AppStrings.congratulations,
                            style: Theme.of(context).textTheme.titleSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            AppStrings.itemUploadedSuccessfully,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  if (ModalRoute.of(context)?.isCurrent != true) return;
                  final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
                  navigationProvider.goBack();
                },
                child: Text(AppStrings.continueText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
