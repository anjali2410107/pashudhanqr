# Media Capture & Upload App

A Flutter Android application demonstrating an end-to-end mobile workflow: JWT authentication with secure storage and automatic token refresh, device camera photo and video recording with audio, multi-media gallery selection using Android Photo Picker, media preview with video playback, and streaming multipart upload to REST API endpoints with live progress and server echo verification.

---

## Table of Contents

1. [Overview](#overview)
2. [How the App Works on Your Phone]
3. [Architecture and Code Organization]
4. [Key Packages and Technical Stack]
5. [API Endpoints and Data Contracts]
6. [Automatic Token Refresh Workflow]
7. [Device Permissions and Hardware Handling]
8. [Building the Release APK and App Bundle]
9. [Acceptance Scenarios Verification]
---

## Overview

The application provides a complete mobile media pipeline connected to the public testing service `https://api.testingapis.com`:

- **Authentication**: JWT login, Keystore token storage, automatic 401 detection, silent token rotation, single-retry mechanism, and session invalidation.
- **Profile Management**: Profile retrieval from protected endpoints, user role parsing, and JWT claims inspection.
- **Camera Capture**: Hardware camera access for photos and video recording with microphone audio, front and back camera toggling, elapsed recording timer, and hardware disposal on pause.
- **Gallery Integration**: Android Photo Picker for multi-media selection without broad external storage permissions, MIME type resolution, and file size detection.
- **Media Preview**: Pinch-to-zoom image viewer, video player with custom controls overlay and timeline scrubbing, file metadata display, and optional description input.
- **Multipart Upload**: Memory-safe file streaming directly from disk via Dio, live progress bar, server echo response verification, batch queue uploading, and error retry support.

---

## How the App Works on Your Phone

### Step 1: Install and Launch the Application

1. Transfer `app-release.apk` to your Android device or install it via ADB:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```
2. Locate the app named **Media Capture & Upload** on your home screen or app drawer.
3. Tap the app icon to launch. The app initializes Flutter bindings, sets the system status bar, and checks local secure storage for an existing session.

### Step 2: Sign In (Authentication)

1. The Login screen appears with a clean interface featuring username and password input fields.
2. Enter the test credentials:
   - **Username**: `user`
   - **Password**: `user123`
3. Tap **Sign In**.
4. The app sends a `POST` request to `https://api.testingapis.com/api/auth/jwt/login`.
5. Upon success:
   - The returned `accessToken` and `refreshToken` are stored in Android Keystore using `flutter_secure_storage`.
   - The user profile is loaded, and you are automatically transitioned to the Dashboard.
6. If invalid credentials are submitted (e.g. `wrong` / `password`), the app displays an error message at the bottom of the screen without crashing.

### Step 3: User Dashboard

1. The Dashboard displays your authenticated profile information:
   - User display name and username initial avatar.
   - Email address.
   - Assigned role badge.
   - Expandable **JWT Claims** section showing token claims and values.
2. The top bar contains:
   - **Refresh icon**: Re-fetches the latest user profile from `GET /api/auth/jwt/me`.
   - **Logout icon**: Displays a confirmation dialog. Confirming logout clears all tokens from secure storage and returns you to the Login screen.
3. Three primary module cards provide navigation:
   - **Device Camera**: Opens full-screen photo and video recording.
   - **Media Gallery**: Opens the device photo and video picker.
   - **Upload Manager**: Opens the upload queue and server echo verification screen.

### Step 4: Device Camera Capture (Photos and Videos)

1. Tap **Device Camera** from the Dashboard.
2. If opening for the first time, the OS prompts for **Camera** and **Microphone** permissions.
3. Once granted, a live camera preview appears.
4. Top Controls:
   - **Close button**: Returns to the Dashboard.
   - **Flip camera button**: Switches between back and front camera sensors.
   - **Recording timer**: Displays elapsed video recording duration.
5. Bottom Controls:
   - **Mode switch**: Tap **PHOTO** or **VIDEO** to switch capture mode.
   - **Capture button**:
     - In **PHOTO** mode: Tapping captures a high-resolution photo and immediately opens the preview.
     - In **VIDEO** mode: Tapping starts video recording with audio and shows a red pulsing timer. Tapping again stops recording and opens the preview.
6. **Resource Safety**: If you switch to another app or lock your phone while on the camera screen, the camera hardware sensor is immediately released to preserve battery. When you switch back, the camera re-initializes seamlessly.

### Step 5: Media Gallery Selection

1. Tap **Media Gallery** from the Dashboard.
2. Choose from three selection options:
   - **Select Multiple Media**: Opens Android's Photo Picker allowing simultaneous selection of multiple photos and videos.
   - **Pick Image**: Selects a single image.
   - **Pick Video**: Selects a single video.
3. Selected files are displayed in a list with:
   - File thumbnail.
   - File name.
   - MIME type tag.
   - Formatted file size.
4. Each selected item has:
   - **Preview button**: Opens full-screen preview.
   - **Delete button**: Removes the item from the selection list.
5. Tap **Add Item(s) to Upload Queue** to enqueue all selected files into the Upload Manager.

### Step 6: Media Preview and Description

1. Opening a photo or video displays the preview screen:
   - **Photos**: Rendered in an interactive viewer supporting pinch-to-zoom and pan gestures.
   - **Videos**: Initialized with auto-play, loop, play/pause controls, and an interactive timeline scrub bar.
2. The bottom sheet displays file metadata (file name, MIME type, file size).
3. An optional **Description** input allows adding metadata to accompany the file upload.
4. Action buttons:
   - **Retake / Discard**: Discards the file and returns to capture or selection.
   - **Accept & Add**: Enqueues the file directly into the Upload Manager and returns to the previous screen.

### Step 7: Upload Manager (Multipart Upload and Echo Verification)

1. Tap **Upload Manager** from the Dashboard (or accept media from preview/gallery).
2. The queue header displays the total number of files, pending count, and completed count.
3. If pending files exist, tap the **Upload All (N)** button to upload all queued files in sequence, or tap **Upload** on an individual card.
4. During upload:
   - File data streams directly from device storage without reading the entire file into RAM, preventing out-of-memory errors on large videos.
   - A real-time progress bar and percentage indicator track bytes transferred over the network.
5. Upon successful upload to `https://api.testingapis.com/api/echo`:
   - A green **Upload Verified** section appears on the card.
   - Confirms the server-received file name.
   - Displays the server-detected MIME content-type.
   - Displays the exact byte size recorded by the server.
   - Shows echoed metadata fields (media type, description, timestamp).
6. If an upload fails due to network disconnection, an error notice appears with a **Retry** button.
7. Tap the broom icon in the top right to clear completed uploads from the list.

### Step 8: Silent Token Refresh

1. When making protected API requests (such as fetching user profile), the app attaches `Authorization: Bearer <accessToken>`.
2. Access tokens are short-lived (15 minutes). When an access token expires:
   - The REST API responds with HTTP `401 Unauthorized`.
   - The app's network interceptor intercepts the 401 response before the UI sees an error.
   - The interceptor calls `POST /api/auth/jwt/refresh` with the stored refresh token.
   - New rotated access and refresh tokens are saved in Android Keystore.
   - The failed request is retried once with the new access token.
   - The user experiences no interruption or forced logout.
3. If the refresh token is also invalid or expired, the session is cleared and the user is redirected to the Login screen.

---

## Architecture and Code Organization

The project follows a clean, feature-first modular architecture separating state management, domain logic, data sources, and user interface:

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart
│   ├── errors/
│   │   └── app_exception.dart
│   ├── network/
│   │   ├── auth_interceptor.dart
│   │   └── dio_client.dart
│   ├── storage/
│   │   └── token_storage.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── file_utils.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── auth_tokens_model.dart
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       └── screens/
│   │           └── login_screen.dart
│   ├── dashboard/
│   │   └── presentation/
│   │       └── screens/
│   │           └── dashboard_screen.dart
│   ├── camera/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── camera_screen.dart
│   │           └── media_preview_screen.dart
│   ├── gallery/
│   │   └── presentation/
│   │       └── screens/
│   │           └── gallery_picker_screen.dart
│   └── upload/
│       ├── data/
│       │   ├── models/
│       │   │   ├── echo_response_model.dart
│       │   │   └── upload_item.dart
│       │   └── repositories/
│       │       └── upload_repository.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── upload_bloc.dart
│           │   ├── upload_event.dart
│           │   └── upload_state.dart
│           └── screens/
│               └── upload_screen.dart
└── main.dart
```

---

## Key Packages and Technical Stack

| Package | Version | Usage |
| :--- | :--- | :--- |
| `flutter_bloc` | `^9.1.1` | Predictable state management across authentication and upload queues |
| `equatable` | `^3.0.0` | Value comparison for immutable state transitions |
| `dio` | `^5.11.1` | HTTP networking with queued interceptors and upload progress tracking |
| `flutter_secure_storage` | `^11.2.0` | Hardware-backed encrypted storage for JWT tokens |
| `camera` | `^0.12.2` | Direct camera sensor control, photo capture, and video recording |
| `image_picker` | `^1.2.4` | System Photo Picker integration for images and videos |
| `video_player` | `^2.14.1` | Local video playback and timeline scrub control |
| `permission_handler` | `^13.0.2` | Runtime permission requests and app settings navigation |
| `mime` | `^2.1.0` | MIME type resolution by header magic numbers and file extensions |
| `http_parser` | `^4.1.2` | MediaType parsing for multipart form headers |
| `intl` | `^0.20.3` | Date, time, and number formatting |

---

## API Endpoints and Data Contracts

Base URL: `https://api.testingapis.com`

| Method | Endpoint | Purpose | Request Payload | Response |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/jwt/login` | Authenticate user | `{"username": "user", "password": "user123"}` | `{"accessToken": "...", "refreshToken": "...", "user": {...}}` |
| `POST` | `/api/auth/jwt/refresh` | Rotate tokens | `{"refreshToken": "..."}` | `{"accessToken": "...", "refreshToken": "..."}` |
| `GET` | `/api/auth/jwt/me` | Fetch user profile | Bearer token in Authorization header | `{"username": "user", "name": "...", "claims": [...]}` |
| `POST` | `/api/echo` | Multipart media upload | Form-data with file part and metadata | `{"files": [{"fileName": "...", "contentType": "...", "size": 123}]}` |

---

## Automatic Token Refresh Workflow

```
[Protected Request]
       │
       ▼
Attach Bearer Token
       │
       ▼
Server Response: HTTP 401 Unauthorized
       │
       ▼
AuthInterceptor Queued Lock
       │
       ├─ Has request been retried already?
       │   └─ Yes: Clear tokens, notify UI, navigate to Login
       │
       └─ No: Send POST /api/auth/jwt/refresh
              │
              ├─ Refresh Success (200 OK):
              │   ├── Store new rotated tokens in Keystore
              │   ├── Update request Authorization header
              │   └── Retry original request once
              │
              └─ Refresh Failure:
                  ├── Clear Keystore session
                  └── Redirect to Login screen
```

---

## Device Permissions and Hardware Handling

Declared in `android/app/src/main/AndroidManifest.xml`:

- `android.permission.INTERNET`: Required for REST API communication.
- `android.permission.CAMERA`: Required for taking photos and recording video.
- `android.permission.RECORD_AUDIO`: Required for capturing microphone audio with video.
- `android.permission.READ_MEDIA_IMAGES`: Android 13+ granular photo access.
- `android.permission.READ_MEDIA_VIDEO`: Android 13+ granular video access.
- `android.permission.READ_EXTERNAL_STORAGE`: Legacy support for Android 12 and below.

Hardware sensors are configured as optional to ensure compatibility across devices:

```xml
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
<uses-feature android:name="android.hardware.microphone" android:required="false" />
```

If a user denies permission, the app presents an informative dialog with a direct button to open the device's system settings.

---

## Building the Release APK and App Bundle

### Prerequisites

- Flutter SDK `3.47.7` stable or higher
- Android SDK with platform API 36 / 37 installed
- Java Development Kit 17

### Build Release APK

From the root project directory:

```bash
flutter build apk --release
```

Output binary:
`build/app/outputs/flutter-apk/app-release.apk`

### Build Android App Bundle (.aab)

```bash
flutter build appbundle --release
```

Output bundle:
`build/app/outputs/bundle/release/app-release.aab`

---

## Acceptance Scenarios Verification

| Scenario | User Action | Verified Behavior | Result |
| :--- | :--- | :--- | :---: |
| **Valid Login** | Enter `user` / `user123` | Authenticated, tokens stored, navigated to Dashboard | **PASSED** |
| **Invalid Login** | Enter incorrect credentials | Error notice shown, app stays responsive without crashing | **PASSED** |
| **Profile Display** | Open Dashboard or tap refresh | Authenticated name, email, role, and claims displayed | **PASSED** |
| **Camera Capture** | Take photo in Camera screen | Captures image, previews with metadata, enqueues to upload | **PASSED** |
| **Video Recording** | Record video in Camera screen | Records video with audio, elapsed timer, preview with player | **PASSED** |
| **Gallery Multi-Pick**| Tap Select Multiple Media | Android Photo Picker selects photos and videos, adds to queue | **PASSED** |
| **Multipart Upload** | Tap Upload or Upload All | Live progress bar, streams from disk, server echo verified | **PASSED** |
| **Silent Refresh** | Access token expires (401) | Auto-refreshes token pair, retries request seamlessly | **PASSED** |
| **Session Cleanup** | Tap Logout in Dashboard | Deletes Keystore credentials, returns to Login screen | **PASSED** |
| **Release Execution** | Install on physical Android device | Installs and runs smoothly in release mode without errors | **PASSED** |
