# Google Play Data Safety Declaration Guide

## Overview

This guide details the exact responses required in the Google Play Console **Data Safety** form for the Cherry MVP application regarding **Photos and Videos / Camera** data collection and processing.

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

### 2. Photos and Videos / Camera Data Declaration

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
> "Cherry collects photos taken by the user via the camera or selected from the photo gallery strictly for user-initiated app functionality — specifically to allow users to showcase items being donated/listed on the marketplace and to set their user profile pictures. Photo data is transferred securely over encrypted HTTPS connections and is stored in Google Cloud / Firebase Storage. Photo data is never shared with third-party advertisers or sold."

---

## Verification & Compliance Checklist
- [x] `android.permission.CAMERA` declared in `AndroidManifest.xml` with `android.hardware.camera` feature flag set to `required="false"`.
- [x] In-app pre-permission dialog explaining camera access before launching system camera picker.
- [x] User camera usage description updated in iOS `Info.plist`.
- [x] Data Safety declarations filled out on Google Play Console as detailed above.
