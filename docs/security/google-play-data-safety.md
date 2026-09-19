# Google Play Data Safety Declaration Guide

## Overview

This guide details the exact responses required in the Google Play Console **Data Safety** form for the Cherry MVP application regarding **Photos / Camera** data collection and processing.

---

## Data Safety Questionnaire Answers

### 1. Data Collection and Security
* **Does your app collect or share any of the required user data types?**
  * **Answer**: Yes.
* **Is all of the user data collected by your app encrypted in transit?**
  * **Answer**: Yes (All transfers occur over HTTPS/TLS).
* **Do you provide a way for users to request that their data be deleted?**
  * **Answer**: Yes (Account deletion request process and policy are documented).

---

### 2. Photos / Camera Data Declaration

#### Data Type: **Photos**
* **Is this data collected, shared, or both?**
  * **Answer**: **Collected** (The app uploads user-selected or newly taken photos to Firebase Cloud Storage for item listings and user profile avatars).
* **Is this data processed ephemerally?**
  * **Answer**: **No** (Photos are stored persistently on cloud storage to display item listings and user profile avatars).
* **Is this data required for your app, or can users choose whether it is collected?**
  * **Answer**: **Data collection is optional / user-initiated** (Users choose to capture/upload photos when listing an item or setting a profile picture).
* **Why is this user data collected?**
  * **Select**:
    * **App functionality**: Users upload photos to describe marketplace donation listings and set profile avatars.

---

### 3. Purpose Summary for App Review & Privacy Policy

> **Privacy Statement Summary for Google Play Reviewers:**
> "Cherry collects photos captured or selected by the user only when the user chooses to create or upload listing or profile media. This functionality is used to present donated or listed items in the marketplace and to set profile media. Photos are transferred securely over encrypted HTTPS connections and stored in Google Cloud / Firebase Storage. The current MVP does not record video or audio and does not collect microphone data."

---

## Verification & Compliance Checklist
- [x] `android.permission.CAMERA` declared in `AndroidManifest.xml` with `android.hardware.camera` feature flag set to `required="false"`.
- [x] No `android.permission.RECORD_AUDIO` declaration because the current MVP has no audio or video capture flow.
- [x] In-app pre-permission dialog explains camera access before launching the system camera picker.
- [x] User-facing “Open Settings” recovery action included when permission is denied.
- [x] Camera usage description updated in iOS `Info.plist`; no microphone description is declared.
- [x] Data Safety declarations filled out on Google Play Console as detailed above.
