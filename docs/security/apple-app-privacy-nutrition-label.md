# Apple App Privacy Nutrition Label Declaration

## Overview

This document records the Apple App Privacy "Nutrition Label" information for the Cherry MVP application regarding user media capture and usage. This serves as the repo-based counterpart to the Google Play Data Safety declaration and should be reviewed alongside the platform privacy disclosures before store submission.

---

## Data Types

### Camera
- Category: Photos and videos
- Purpose: Users take photos or record videos of donated or listed items so they can create marketplace listings and profile content.
- User choice: Optional and user-initiated.
- Collection: On-device capture and upload to app storage when the user chooses to use the feature.

### Microphone
- Category: Audio
- Purpose: Microphone access is required when the user records a video with audio for item listings or media content.
- User choice: Optional and user-initiated.
- Collection: Only when the user explicitly records audio/video content.

### Photos and Videos
- Category: User-generated content
- Purpose: App functionality for listing donated items, presenting marketplace media, and optional profile media.
- User choice: Optional and user-initiated.
- Retention: Stored in cloud storage for listing display and profile media until the user removes, updates, or deletes the underlying listing or profile content.

---

## Apple App Privacy Summary

> Cherry uses camera and microphone access only when the user chooses to take a photo or record a short video for a listing or profile. This technology is used to support product/media upload for the marketplace, and the media is stored in the app's cloud storage for display in the app. The app does not use these permissions for advertising, tracking, or third-party profiling.

---

## App Store Review / Compliance Notes
- Camera and microphone access are disclosed in the app's usage descriptions for iOS.
- Users are informed before access is requested through an in-app rationale dialog and are given a direct path to device settings if permission is denied.
- Permissions are limited to the user-initiated media creation flow and are not used for background surveillance or unrelated data collection.
- The app's privacy documentation should be kept consistent with actual functionality and store declarations.

---

## Verification Checklist
- [x] Camera usage description added to iOS `Info.plist`.
- [x] Microphone usage description added to iOS `Info.plist`.
- [x] App functionality matches camera and microphone permissions in the app.
- [x] App provides a direct "Open Settings" recovery action when permission is denied.
- [x] Google Play Data Safety doc exists and reflects the same user-initiated media flow.
