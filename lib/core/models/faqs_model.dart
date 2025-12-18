import 'package:cherry_mvp/core/config/app_strings.dart';

class FaqEntry {
  final String question;
  final String answer;

  const FaqEntry({required this.question, required this.answer});
}

class FaqCategory {
  final String title;
  final List<FaqEntry> entries;

  const FaqCategory({required this.title, required this.entries});
}

//Faq dummy data
final List<FaqCategory> dummyFaqData = [
  // 1. General Info
  FaqCategory(
    title: AppStrings.generalInfo,
    entries: [
      FaqEntry(
        question: AppStrings.whatIsCherryQuestion,
        answer: AppStrings.whatIsCherryAnswer,
      ),
      FaqEntry(
        question: AppStrings.whoCanSellQuestion,
        answer: AppStrings.whoCanSellAnswer,
      ),
    ],
  ),

  // 2. Offers
  FaqCategory(
    title: AppStrings.offers,
    entries: [
      FaqEntry(
        question: AppStrings.howDoIOfferQuestion,
        answer: AppStrings.howDoIOfferAnswer,
      ),
      FaqEntry(
        question: AppStrings.offerDeclinedQuestion,
        answer: AppStrings.offerDeclinedAnswer,
      ),
    ],
  ),

  // 3. Selling
  FaqCategory(
    title: AppStrings.selling,
    entries: [
      FaqEntry(
        question: AppStrings.listItemQuestion,
        answer: AppStrings.listItemAnswer,
      ),
      FaqEntry(
        question: AppStrings.pickCharityQuestion,
        answer: AppStrings.pickCharityAnswer,
      ),
    ],
  ),

  // 4. Buying
  FaqCategory(
    title: AppStrings.buying,
    entries: [
      FaqEntry(
        question: AppStrings.deliveryOptionsQuestion,
        answer: AppStrings.deliveryOptionsAnswer,
      ),
      FaqEntry(
        question: AppStrings.purchaseSecurityQuestion,
        answer: AppStrings.purchaseSecurityAnswer,
      ),
    ],
  ),

  // 5. Trust & Safety
  FaqCategory(
    title: AppStrings.trustAndSafety,
    entries: [
      FaqEntry(
        question: AppStrings.transactionSafetyQuestion,
        answer: AppStrings.transactionSafetyAnswer,
      ),
      FaqEntry(
        question: AppStrings.refundPolicyQuestion,
        answer: AppStrings.refundPolicyAnswer,
      ),
    ],
  ),
];
