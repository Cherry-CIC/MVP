# Apple App Privacy Nutrition Label Declaration

## Overview

This document records the Apple App Privacy "Nutrition Label" information for the Cherry MVP application regarding user photo capture and usage. This serves as the repo-based counterpart to the Google Play Data Safety declaration and should be reviewed alongside the platform privacy disclosures before store submission.

---

## Data Types

### Camera
- Category: Photos and videos
- Purpose: Users take photos of donated or listed items so they can create marketplace listings and profile content.
- User choice: Optional and user-initiated.
- Collection: On-device capture and upload to app storage when the user chooses to use the feature.

### Photos and Videos
- Category: Photos
- Purpose: App functionality for listing donated items, presenting marketplace media, and optional profile media.
- User choice: Optional and user-initiated.
- Retention: Stored in cloud storage for listing display and profile media until the user removes, updates, or deletes the underlying listing or profile content.

---

## Apple App Privacy Summary

> Cherry uses camera access only when the user chooses to take a photo for a listing or profile. Photos support marketplace listings and profile media and are stored in the app's cloud storage for display in the app. The current MVP does not record video or audio and does not request microphone access.

---

## App Store Review / Compliance Notes
- Camera access is disclosed in the app's usage description for iOS. Microphone access is not declared because the current MVP does not use it.
- Users are informed before access is requested through an in-app rationale dialog and are given a direct path to device settings if permission is denied.
- Permissions are limited to the user-initiated media creation flow and are not used for background surveillance or unrelated data collection.
- The app's privacy documentation should be kept consistent with actual functionality and store declarations.

---

## Verification Checklist
- [x] Camera usage description added to iOS `Info.plist`.
- [x] No microphone usage description is declared because the current MVP has no audio or video capture flow.
- [x] App functionality matches the camera permission declared by the app.
- [x] App provides a direct "Open Settings" recovery action when permission is denied.
- [x] Google Play Data Safety doc exists and reflects the same user-initiated media flow.
