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

### 2. Photos, Videos, and Audio / Camera Data Declaration

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

#### Data Type: **Videos**
* **Is this data collected, shared, or both?**
  * **Answer**: **Collected** (The app may capture and upload short videos for item listings and profile media when the user explicitly chooses to record video content).
* **Is this data processed ephemerally?**
  * **Answer**: **No** (Video files are stored in Firebase Cloud Storage to display listing media and user profile content).
* **Is this data required for your app, or can users choose whether it is collected?**
  * **Answer**: **Data collection is optional / user-initiated** (Users decide whether to record a video or upload media as part of a listing flow).
* **Why is this user data collected?**
  * **Select**:
    * **App functionality**: Users record or upload item videos to provide richer marketplace listing information and optional profile content.

#### Data Type: **Audio**
* **Is this data collected, shared, or both?**
  * **Answer**: **Collected** (The app captures microphone input when the user records video or audio content as part of listing media).
* **Is this data processed ephemerally?**
  * **Answer**: **No** (Audio attached to recorded video is stored with the media in cloud storage when the user chooses to record it).
* **Is this data required for your app, or can users choose whether it is collected?**
  * **Answer**: **Data collection is optional / user-initiated** (Users opt in to record audio as part of the listing media or profile media process).
* **Why is this user data collected?**
  * **Select**:
    * **App functionality**: Microphone input supports recorded item videos and user-created media content.

---

### 3. Purpose Summary for App Review & Privacy Policy

> **Privacy Statement Summary for Google Play Reviewers:**
> "Cherry collects photos, videos, and microphone audio captured by the user only when the user chooses to create or upload listing or profile media. This functionality is used to present donated or listed items in the marketplace and to set profile media. Media is transferred securely over encrypted HTTPS connections and stored in Google Cloud / Firebase Storage. Media is never shared with third-party advertisers or sold."

---

## Verification & Compliance Checklist
- [x] `android.permission.CAMERA` declared in `AndroidManifest.xml` with `android.hardware.camera` feature flag set to `required="false"`.
- [x] `android.permission.RECORD_AUDIO` declared for video-capable listing media flow.
- [x] In-app pre-permission dialog explaining camera and microphone access before launching system camera picker or recording flow.
- [x] User-facing “Open Settings” recovery action included when permission is denied.
- [x] Camera and microphone usage descriptions updated in iOS `Info.plist`.
- [x] Data Safety declarations filled out on Google Play Console as detailed above.
