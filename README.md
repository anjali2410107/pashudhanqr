# Media Capture & Upload App (Flutter / Android)
# Media Capture & Upload App

A production-ready Flutter Android application demonstrating an end-to-end mobile workflow: JWT authentication with silent token refresh, camera photo & video capture with audio, multi-file gallery selection using Android's Photo Picker, preview and metadata inspection, and streaming multipart upload to REST API endpoints with progress reporting and echo response validation.
A Flutter Android application demonstrating an end-to-end mobile workflow: JWT authentication with secure storage and automatic token refresh, device camera photo and video recording with audio, multi-media gallery selection using Android Photo Picker, media preview with video playback, and streaming multipart upload to REST API endpoints with live progress and server echo verification.

---

## Table of Contents
1. [Overview & Features](#overview--features)
2. [Tech Stack & Key Packages](#tech-stack--key-packages)
3. [Architecture Overview](#architecture-overview)
4. [API Endpoints & Contracts](#api-endpoints--contracts)
5. [JWT Authentication & Token Refresh Flow](#jwt-authentication--token-refresh-flow)
6. [Camera & Video Handling](#camera--video-handling)
7. [Gallery & Local File Access](#gallery--local-file-access)
8. [Multipart Upload Mechanism](#multipart-upload-mechanism)
9. [Android Permissions & Photo Picker](#android-permissions--photo-picker)
10. [Release Build & Signing Instructions](#release-build--signing-instructions)
11. [Acceptance Scenarios Verification Matrix](#acceptance-scenarios-verification-matrix)
12. [Incomplete Items, Assumptions & Known Limitations](#incomplete-items-assumptions--known-limitations)

1. [Overview](#overview)
2. [How the App Works on Your Phone](#how-the-app-works-on-your-phone)
3. [Architecture and Code Organization](#architecture-and-code-organization)
4. [Key Packages and Technical Stack](#key-packages-and-technical-stack)
5. [API Endpoints and Data Contracts](#api-endpoints-and-data-contracts)
6. [Automatic Token Refresh Workflow](#automatic-token-refresh-workflow)
7. [Device Permissions and Hardware Handling](#device-permissions-and-hardware-handling)
8. [Building the Release APK and App Bundle](#building-the-release-apk-and-app-bundle)
9. [Acceptance Scenarios Verification](#acceptance-scenarios-verification)

---

## 1. Overview & Features
## Overview

- **JWT Authentication & Session Management**:
  - Secure login with credential validation.
  - Storage of tokens via `flutter_secure_storage` (backed by Android Keystore).
  - Dio Queued Interceptor that automatically detects HTTP `401 Unauthorized`, initiates a single token refresh against `/api/auth/jwt/refresh`, rotates stored tokens, and seamlessly retries the original request once.
  - Automatic session cleanup and redirect to login if refresh fails.
  - Dedicated **JWT Refresh Testing Lab** on the Dashboard to simulate token expiration and refresh failures with a single tap.
- **User Dashboard**:
  - Displays authenticated user profile fetched from `GET /api/auth/jwt/me`.
  - Parses role, email, and claims.
  - Refresh profile action and logout confirmation dialog.
- **Device Camera Capture & Video Recording**:
  - Live full-screen camera preview with front/back camera toggling.
  - Photo capture mode.
  - Video recording mode with live recording duration timer and audio capture.
  - Graceful permission denial handling with an direct option to open Android App Settings.
  - Full lifecycle management (`WidgetsBindingObserver`) disposing camera hardware when backgrounded or navigated away.
- **Media Preview & Validation**:
  - Image viewer with pinch-to-zoom (`InteractiveViewer`).
  - Video player with play/pause overlay, timeline scrubbing, and auto-looping.
  - Displays file name, detected MIME type, and formatted file size (e.g., KB, MB).
  - Allows adding an optional user description.
  - Discard/retake or accept into upload queue.
- **Media Gallery Selection**:
  - Android Photo Picker integration (`image_picker`) supporting multi-selection of photos and videos without requesting broad external storage permissions.
  - Validates file existence, supported MIME types, and prevents duplicate entries.
  - Batch action to enqueue selected media items.
- **Multipart Media Upload**:
  - Uploads to `POST https://api.testingapis.com/api/echo` using Dio.
  - Memory-efficient disk streaming using `MultipartFile.fromFile` to prevent Out-Of-Memory (OOM) on large videos.
  - Real-time upload progress percentage and progress bar.
  - Echo response verification: parses and renders echoed file name, content type, and server-measured byte size.
  - Error recovery and retry action on failed uploads.
  - Test simulation toggles (`?delay=3` for slow network simulation and `?error=503` for server error recovery).
The application provides a complete mobile media pipeline connected to the public testing service `https://api.testingapis.com`:

- **Authentication**: JWT login, Keystore token storage, automatic 401 detection, silent token rotation, single-retry mechanism, and session invalidation.
- **Profile Management**: Profile retrieval from protected endpoints, user role parsing, and JWT claims inspection.
- **Camera Capture**: Hardware camera access for photos and video recording with microphone audio, front and back camera toggling, elapsed recording timer, and hardware disposal on pause.
- **Gallery Integration**: Android Photo Picker for multi-media selection without broad external storage permissions, MIME type resolution, and file size detection.
- **Media Preview**: Pinch-to-zoom image viewer, video player with custom controls overlay and timeline scrubbing, file metadata display, and optional description input.
- **Multipart Upload**: Memory-safe file streaming directly from disk via Dio, live progress bar, server echo response verification, batch queue uploading, and error retry support.

---

## 2. Tech Stack & Key Packages
## How the App Works on Your Phone

- **Framework**: Flutter `3.47.7` (Channel stable)
- **Language**: Dart `3.13.5`
- **Minimum Android SDK**: Android API 24 (Android 7.0+)
- **Target / Compile SDK**: Android API 36 / 37
- **Key Dependencies**:
  | Package | Version | Purpose |
  | :--- | :--- | :--- |
  | `flutter_bloc` | `^9.1.1` | Predictable state management separating UI from business logic |
  | `equatable` | `^3.0.0` | Value equality for states and events to prevent unnecessary rebuilds |
  | `dio` | `^5.11.1` | HTTP client with queued interceptors, cancellation, and progress tracking |
  | `flutter_secure_storage` | `^11.2.0` | Encrypted token storage utilizing Android Keystore |
  | `camera` | `^0.12.2` | Direct hardware camera control for photo and video recording |
  | `image_picker` | `^1.2.4` | System Photo Picker integration for images and videos |
  | `video_player` | `^2.14.1` | Local video playback and timeline controls |
  | `permission_handler` | `^13.0.2` | Runtime permission requests and app settings navigation |
  | `mime` | `^2.1.0` | MIME type resolution by header magic numbers & file extension |
  | `http_parser` | `^4.1.2` | MediaType parsing for multipart headers |
  | `intl` | `^0.20.3` | Date, time, and number formatting |
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

## 3. Architecture Overview
## Architecture and Code Organization

The application follows **Clean Feature-First Architecture**:
The project follows a clean, feature-first modular architecture separating state management, domain logic, data sources, and user interface:

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart          # Base URL, endpoints, test credentials, timeouts
│   │   └── api_constants.dart
│   ├── errors/
│   │   └── app_exception.dart          # Custom domain and network exception classes
│   │   └── app_exception.dart
│   ├── network/
│   │   ├── auth_interceptor.dart       # Dio QueuedInterceptor: 401 handling, refresh & retry
│   │   └── dio_client.dart             # Centralized Dio instance with interceptors
│   │   ├── auth_interceptor.dart
│   │   └── dio_client.dart
│   ├── storage/
│   │   └── token_storage.dart          # Wrapper around flutter_secure_storage
│   │   └── token_storage.dart
│   ├── theme/
│   │   └── app_theme.dart              # Material 3 theme, colors, typography, shapes
│   │   └── app_theme.dart
│   └── utils/
│       └── file_utils.dart             # Human-readable size formatting, MIME detection
│       └── file_utils.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── auth_tokens_model.dart  # Access and refresh token JSON model
│   │   │   │   └── user_model.dart         # User profile and claims JSON model
│   │   │   │   ├── auth_tokens_model.dart
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart    # Login, profile fetch, token injection
│   │   │       └── auth_repository.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart          # Auth business logic
│   │       │   ├── auth_event.dart         # Auth events
│   │       │   └── auth_state.dart         # Auth states (Authenticated, Loading, etc.)
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       └── screens/
│   │           └── login_screen.dart       # Login UI with demo credentials autofill
│   │           └── login_screen.dart
│   ├── dashboard/
│   │   └── presentation/
│   │       └── screens/
│   │           └── dashboard_screen.dart   # Profile details, module links, JWT testing lab
│   │           └── dashboard_screen.dart
│   ├── camera/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── camera_screen.dart      # Photo/video capture with lifecycle management
│   │           └── media_preview_screen.dart # Image/video preview with scrubbing & controls
│   │           ├── camera_screen.dart
│   │           └── media_preview_screen.dart
│   ├── gallery/
│   │   └── presentation/
│   │       └── screens/
│   │           └── gallery_picker_screen.dart # Android Photo Picker, multi-selection
│   │           └── gallery_picker_screen.dart
│   └── upload/
│       ├── data/
│       │   ├── models/
│       │   │   ├── echo_response_model.dart # Parsed echo JSON response
│       │   │   └── upload_item.dart         # Local upload queue item model
│       │   │   ├── echo_response_model.dart
│       │   │   └── upload_item.dart
│       │   └── repositories/
│       │       └── upload_repository.dart   # Multipart Dio POST with progress & simulations
│       │       └── upload_repository.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── upload_bloc.dart         # Upload queue, progress & status state
│           │   ├── upload_event.dart        # Queue add, remove, upload start, retry
│           │   └── upload_state.dart        # Active upload state & progress metrics
│           │   ├── upload_bloc.dart
│           │   ├── upload_event.dart
│           │   └── upload_state.dart
│           └── screens/
│               └── upload_screen.dart       # Upload manager UI with echo details card
└── main.dart                                # Dependency injection and app startup
│               └── upload_screen.dart
└── main.dart
```

---

## 4. API Endpoints & Contracts
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

| Method | Endpoint | Description | Request / Response Structure |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/jwt/login` | Authenticate with credentials | **Body**: `{"username": "user", "password": "user123"}`<br>**Response**: `{"accessToken": "...", "refreshToken": "...", "expiresIn": 900, "user": {...}}` |
| `POST` | `/api/auth/jwt/refresh` | Rotate expired token pair | **Body**: `{"refreshToken": "..."}`<br>**Response**: `{"accessToken": "...", "refreshToken": "...", ...}` |
| `GET` | `/api/auth/jwt/me` | Fetch authenticated user | **Headers**: `Authorization: Bearer <accessToken>`<br>**Response**: `{"username": "user", "name": "Uma User", "claims": [...]}` |
| `GET` | `/api/auth/jwt/expired` | Test helper for expired JWT | **Response**: `{"accessToken": "<expired_jwt>", "message": "..."}` |
| `POST` | `/api/echo` | Multipart media upload echo | **FormData**: `file: <binary>`, `mediaType: "image/jpeg"`, `description: "..."`<br>**Response**: `{"files": [{"field": "file", "fileName": "...", "contentType": "...", "size": 1234}], "form": {...}}` |
| Method | Endpoint | Purpose | Request Payload | Response |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/jwt/login` | Authenticate user | `{"username": "user", "password": "user123"}` | `{"accessToken": "...", "refreshToken": "...", "user": {...}}` |
| `POST` | `/api/auth/jwt/refresh` | Rotate tokens | `{"refreshToken": "..."}` | `{"accessToken": "...", "refreshToken": "..."}` |
| `GET` | `/api/auth/jwt/me` | Fetch user profile | Bearer token in Authorization header | `{"username": "user", "name": "...", "claims": [...]}` |
| `POST` | `/api/echo` | Multipart media upload | Form-data with file part and metadata | `{"files": [{"fileName": "...", "contentType": "...", "size": 123}]}` |

---

## 5. JWT Authentication & Token Refresh Flow
## Automatic Token Refresh Workflow

The authentication system employs a non-blocking `QueuedInterceptor` pattern:

```
[UI / Protected Request]
[Protected Request]
       │
       ▼ (Attach Bearer Token)
[GET /api/auth/jwt/me] ──> Server (200 OK) ──> Return Profile Data
       ▼
Attach Bearer Token
       │
       └──> Server responds 401 Unauthorized
                 │
                 ▼
         [AuthInterceptor]
                 │
        Is request retried already?
        ├─ Yes ──> Emit Session Expired ──> Redirect to Login
        └─ No  ──> Check if refresh currently running
                    │
                    ▼
          [POST /api/auth/jwt/refresh]
                    │
            ┌───────┴───────┐
            │ Success       │ Failure (401/403/Network)
            ▼               ▼
     Store new Tokens   Clear TokenStorage
     Update Request     Emit Session Expired
     Authorization      Redirect to Login
            │
            ▼
     Retry Original Request (1 time)
            │
            ▼
     Return 200 Response to Caller
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

### Testing Expiry in the App
Under the **JWT Refresh Testing Lab** on the Dashboard:
1. Tap **"Test Token Expiry & Auto-Refresh (Scenario 4)"**:
   - Fetches an expired token from `/api/auth/jwt/expired`.
   - Injects it into `TokenStorage`.
   - Triggers `GET /api/auth/jwt/me`.
   - The interceptor receives 401, calls `/api/auth/jwt/refresh`, stores the rotated tokens, and retries `GET /api/auth/jwt/me`.
   - A success banner confirms the roundtrip.
2. Tap **"Test Refresh Failure -> Auto Logout (Scenario 5)"**:
   - Injects an invalid refresh token alongside an expired access token.
   - Triggers `GET /api/auth/jwt/me`.
   - Refresh fails; session is cleared and the app automatically transitions to the Login screen with an alert.

---

## 6. Camera & Video Handling
## Device Permissions and Hardware Handling

- **CameraController Lifecycle**:
  - Attached to `WidgetsBindingObserver`.
  - When the user navigates away or moves the app to the background (`AppLifecycleState.paused` / `inactive`), the camera controller is immediately disposed, releasing the hardware sensor.
  - Re-initializes on `AppLifecycleState.resumed`.
- **Photo Capture**: Uses `controller.takePicture()` and passes the temporary image path to `MediaPreviewScreen`.
- **Video Capture with Audio**:
  - Uses `controller.startVideoRecording()` and `controller.stopVideoRecording()`.
  - Timer ticker displays elapsed recording time (e.g. `00:15`).
  - Recorded video with audio is routed to `MediaPreviewScreen`.
- **Preview & Playback**:
  - `video_player` controller is initialized for video review.
  - Includes play/pause toggle overlay and scrubbing progress indicator.
  - Video controller is cleanly disposed on screen exit.
Declared in `android/app/src/main/AndroidManifest.xml`:

---
- `android.permission.INTERNET`: Required for REST API communication.
- `android.permission.CAMERA`: Required for taking photos and recording video.
- `android.permission.RECORD_AUDIO`: Required for capturing microphone audio with video.
- `android.permission.READ_MEDIA_IMAGES`: Android 13+ granular photo access.
- `android.permission.READ_MEDIA_VIDEO`: Android 13+ granular video access.
- `android.permission.READ_EXTERNAL_STORAGE`: Legacy support for Android 12 and below.

## 7. Gallery & Local File Access
Hardware sensors are configured as optional to ensure compatibility across devices:

- Utilizes Android's current system **Photo Picker** (`image_picker` `pickMultipleMedia()`).
- Does **not** require broad `READ_EXTERNAL_STORAGE` on Android 13+ (API 33+) due to system photo picker sandboxing.
- Supports selecting multiple images and videos in a single action.
- Detects MIME types and sizes dynamically.
- Gracefully skips missing or unsupported files and notifies the user with a summary toast.
- Allows discarding selected media items before submitting to the upload queue.

---

## 8. Multipart Upload Mechanism

### Memory-Efficient File Streaming
Rather than loading an entire high-definition video (which could be tens or hundreds of megabytes) into RAM as a byte array, the app uses:
```dart
final multipartFile = await MultipartFile.fromFile(
  item.filePath,
  filename: item.fileName,
  contentType: mediaType,
);
```xml
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
<uses-feature android:name="android.hardware.microphone" android:required="false" />
```
Dio streams the file chunks directly from the disk filesystem into the HTTP socket request stream. This eliminates Android Out-Of-Memory (OOM) crashes on large video uploads.

### Progress Reporting
Upload progress is captured in real-time via Dio's `onSendProgress`:
```dart
onSendProgress: (int sent, int total) {
  if (total > 0 && onProgress != null) {
    onProgress(sent / total);
  }
}
```
The state updates a smooth linear progress bar and percentage indicator.
If a user denies permission, the app presents an informative dialog with a direct button to open the device's system settings.

### Echo Verification
The echo response is parsed into `EchoResponseModel`:
- File Name echoed by server
- Content-Type detected by server
- Byte size calculated by server
- Echoed form fields (`mediaType`, `description`, `uploadedAt`)

---

## 9. Android Permissions & Photo Picker
## Building the Release APK and App Bundle

The app declares only the required permissions in `android/app/src/main/AndroidManifest.xml`:
- `android.permission.INTERNET`: Required for REST API communication.
- `android.permission.CAMERA`: Required for camera photo and video capture.
- `android.permission.RECORD_AUDIO`: Required for capturing audio with video.
- `android.permission.READ_MEDIA_IMAGES` (API 33+): Modern granular media access.
- `android.permission.READ_MEDIA_VIDEO` (API 33+): Modern granular video access.
- `android.permission.READ_EXTERNAL_STORAGE` (`maxSdkVersion="32"`): Legacy compatibility for Android 12 and below.
### Prerequisites

Hardware features are declared with `android:required="false"` to allow installation on diverse devices:
```xml
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
<uses-feature android:name="android.hardware.microphone" android:required="false" />
```
- Flutter SDK `3.47.7` stable or higher
- Android SDK with platform API 36 / 37 installed
- Java Development Kit 17

---
### Build Release APK

## 10. Release Build & Signing Instructions
From the root project directory:

### Application ID
- Configured Application ID: `com.assessment.mediacapture`
- Minimum SDK: `24` (Android 7.0+)
- Target SDK: `36`

### Generating Release APK
Run the following command from the project root:
```bash
flutter build apk --release
```
The installable release APK will be generated at:

Output binary:
`build/app/outputs/flutter-apk/app-release.apk`

### Generating Android App Bundle (.aab)
Run the following command:
### Build Android App Bundle (.aab)

```bash
flutter build appbundle --release
```
The release App Bundle will be generated at:

Output bundle:
`build/app/outputs/bundle/release/app-release.aab`

### Signing Configuration Explanation
For the assessment distribution, the release build type in `android/app/build.gradle.kts` is linked to the standard debug signing key to allow immediate, zero-configuration side-loading and testing on any Android device without signing key errors:
```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
        isMinifyEnabled = false
        isShrinkResources = false
    }
}
```

#### Production Play Store Signing (for production reference)
For actual Google Play Store publishing:
1. Generate a secure keystore:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create a `key.properties` file in `android/`:
   ```properties
   storePassword=<store_password>
   keyPassword=<key_password>
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```
3. Load `key.properties` in `build.gradle.kts` and configure `signingConfigs.create("release")`.
4. Ensure `key.properties` and `.jks` are listed in `.gitignore` to prevent credential leaks.

---

## 11. Acceptance Scenarios Verification Matrix
## Acceptance Scenarios Verification

| Scenario | Trigger / Action | Expected Result | Status |
| Scenario | User Action | Verified Behavior | Result |
| :--- | :--- | :--- | :---: |
| **Valid Login** | Enter `user` / `user123` | Authenticated and navigated to Dashboard | **PASSED** |
| **Invalid Login** | Enter `invalid_user` / `wrong_pass` | Friendly error banner displayed; no crash | **PASSED** |
| **Profile Request** | Automatic on login or tap Refresh icon | User name, role, email, and JWT claims rendered | **PASSED** |
| **Expired Access Token** | Tap "Test Token Expiry & Auto-Refresh" | Interceptor receives 401, calls `/refresh`, rotates tokens, retries `/me` successfully | **PASSED** |
| **Refresh Failure** | Tap "Test Refresh Failure -> Auto Logout" | Refresh returns error, session cleared, redirected to Login screen | **PASSED** |
| **Camera/Mic Permission Denied** | Deny permission prompt | Explanatory message displayed with "Open App Settings" button | **PASSED** |
| **Capture & Gallery Selection** | Take photo/video or select from gallery | Preview displayed with name, MIME type, size; discard/remove supported | **PASSED** |
| **Successful Upload** | Tap "Upload" or "Upload All Pending" | Real-time progress bar; server echo parsed and displayed | **PASSED** |
| **Upload / Server Error** | Toggle `?error=503` in Upload Manager | Error banner shown with dedicated "Retry" button | **PASSED** |
| **Release Build** | Install release APK on device | App installs and runs stably in release mode | **PASSED** |

---

## 12. Incomplete Items, Assumptions & Known Limitations

1. **Echo Endpoint Ephemeral Storage**:
   - `https://api.testingapis.com/api/echo` is a verification echo service that returns request and file metadata. It does not provide persistent cloud storage or download URLs. Echo verification of file name, MIME type, and byte size is fully implemented.
2. **Test Service Size Limitations**:
   - The public test service accepts multipart files up to standard limits. Extremely large files (>10MB) may encounter server-side rate limits or timeout on the public test server.
3. **Camera on Simulators**:
   - When running on Android emulators without a virtual scene camera or on desktop environments without a physical webcam, the app gracefully catches camera hardware unavailability and displays a clear message to the user.
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
