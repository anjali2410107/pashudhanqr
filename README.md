# Media Capture & Upload App (Flutter / Android)

A production-ready Flutter Android application demonstrating an end-to-end mobile workflow: JWT authentication with silent token refresh, camera photo & video capture with audio, multi-file gallery selection using Android's Photo Picker, preview and metadata inspection, and streaming multipart upload to REST API endpoints with progress reporting and echo response validation.

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

---

## 1. Overview & Features

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

---

## 2. Tech Stack & Key Packages

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

---

## 3. Architecture Overview

The application follows **Clean Feature-First Architecture**:

```
lib/
├── core/
│   ├── constants/
│   │   └── api_constants.dart          # Base URL, endpoints, test credentials, timeouts
│   ├── errors/
│   │   └── app_exception.dart          # Custom domain and network exception classes
│   ├── network/
│   │   ├── auth_interceptor.dart       # Dio QueuedInterceptor: 401 handling, refresh & retry
│   │   └── dio_client.dart             # Centralized Dio instance with interceptors
│   ├── storage/
│   │   └── token_storage.dart          # Wrapper around flutter_secure_storage
│   ├── theme/
│   │   └── app_theme.dart              # Material 3 theme, colors, typography, shapes
│   └── utils/
│       └── file_utils.dart             # Human-readable size formatting, MIME detection
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── auth_tokens_model.dart  # Access and refresh token JSON model
│   │   │   │   └── user_model.dart         # User profile and claims JSON model
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart    # Login, profile fetch, token injection
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart          # Auth business logic
│   │       │   ├── auth_event.dart         # Auth events
│   │       │   └── auth_state.dart         # Auth states (Authenticated, Loading, etc.)
│   │       └── screens/
│   │           └── login_screen.dart       # Login UI with demo credentials autofill
│   ├── dashboard/
│   │   └── presentation/
│   │       └── screens/
│   │           └── dashboard_screen.dart   # Profile details, module links, JWT testing lab
│   ├── camera/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── camera_screen.dart      # Photo/video capture with lifecycle management
│   │           └── media_preview_screen.dart # Image/video preview with scrubbing & controls
│   ├── gallery/
│   │   └── presentation/
│   │       └── screens/
│   │           └── gallery_picker_screen.dart # Android Photo Picker, multi-selection
│   └── upload/
│       ├── data/
│       │   ├── models/
│       │   │   ├── echo_response_model.dart # Parsed echo JSON response
│       │   │   └── upload_item.dart         # Local upload queue item model
│       │   └── repositories/
│       │       └── upload_repository.dart   # Multipart Dio POST with progress & simulations
│       └── presentation/
│           ├── bloc/
│           │   ├── upload_bloc.dart         # Upload queue, progress & status state
│           │   ├── upload_event.dart        # Queue add, remove, upload start, retry
│           │   └── upload_state.dart        # Active upload state & progress metrics
│           └── screens/
│               └── upload_screen.dart       # Upload manager UI with echo details card
└── main.dart                                # Dependency injection and app startup
```

---

## 4. API Endpoints & Contracts

Base URL: `https://api.testingapis.com`

| Method | Endpoint | Description | Request / Response Structure |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/jwt/login` | Authenticate with credentials | **Body**: `{"username": "user", "password": "user123"}`<br>**Response**: `{"accessToken": "...", "refreshToken": "...", "expiresIn": 900, "user": {...}}` |
| `POST` | `/api/auth/jwt/refresh` | Rotate expired token pair | **Body**: `{"refreshToken": "..."}`<br>**Response**: `{"accessToken": "...", "refreshToken": "...", ...}` |
| `GET` | `/api/auth/jwt/me` | Fetch authenticated user | **Headers**: `Authorization: Bearer <accessToken>`<br>**Response**: `{"username": "user", "name": "Uma User", "claims": [...]}` |
| `GET` | `/api/auth/jwt/expired` | Test helper for expired JWT | **Response**: `{"accessToken": "<expired_jwt>", "message": "..."}` |
| `POST` | `/api/echo` | Multipart media upload echo | **FormData**: `file: <binary>`, `mediaType: "image/jpeg"`, `description: "..."`<br>**Response**: `{"files": [{"field": "file", "fileName": "...", "contentType": "...", "size": 1234}], "form": {...}}` |

---

## 5. JWT Authentication & Token Refresh Flow

The authentication system employs a non-blocking `QueuedInterceptor` pattern:

```
[UI / Protected Request]
       │
       ▼ (Attach Bearer Token)
[GET /api/auth/jwt/me] ──> Server (200 OK) ──> Return Profile Data
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

---

## 7. Gallery & Local File Access

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

### Echo Verification
The echo response is parsed into `EchoResponseModel`:
- File Name echoed by server
- Content-Type detected by server
- Byte size calculated by server
- Echoed form fields (`mediaType`, `description`, `uploadedAt`)

---

## 9. Android Permissions & Photo Picker

The app declares only the required permissions in `android/app/src/main/AndroidManifest.xml`:
- `android.permission.INTERNET`: Required for REST API communication.
- `android.permission.CAMERA`: Required for camera photo and video capture.
- `android.permission.RECORD_AUDIO`: Required for capturing audio with video.
- `android.permission.READ_MEDIA_IMAGES` (API 33+): Modern granular media access.
- `android.permission.READ_MEDIA_VIDEO` (API 33+): Modern granular video access.
- `android.permission.READ_EXTERNAL_STORAGE` (`maxSdkVersion="32"`): Legacy compatibility for Android 12 and below.

Hardware features are declared with `android:required="false"` to allow installation on diverse devices:
```xml
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
<uses-feature android:name="android.hardware.microphone" android:required="false" />
```

---

## 10. Release Build & Signing Instructions

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
`build/app/outputs/flutter-apk/app-release.apk`

### Generating Android App Bundle (.aab)
Run the following command:
```bash
flutter build appbundle --release
```
The release App Bundle will be generated at:
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

| Scenario | Trigger / Action | Expected Result | Status |
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
