# Feature 4: Guided Camera Viewfinder

## Overview

The guided camera screen now uses Flutter's `camera` package for a real camera feed. The live `CameraPreview` is displayed behind the existing wound-framing guide and lighting advisory banner. Captured images remain in memory and continue through the existing review and upload flow.

## Implementation

- Added `camera` dependency (`^0.11.2+1`).
- Added camera discovery through `availableCameras()`.
- Initializes the first available camera at `ResolutionPreset.medium` with audio disabled.
- Shows a loading indicator while camera initialization is pending.
- Shows a visible initialization or capture error when the camera is unavailable.
- Disposes `CameraController` with the screen lifecycle.
- Replaced the placeholder camera icon with `CameraPreview`.
- Captures with `CameraController.takePicture()` and reads the resulting bytes in memory.
- Routes the captured image to the existing review screen without writing it to local storage.
- Preserved the framing guide painter and lighting advisory overlay above the live preview.
- Prevents duplicate captures while a capture is in progress.

## Runtime Flow

1. Patient detail opens **New analysis**.
2. Clinician chooses **Take photo**.
3. The app discovers and initializes the device camera.
4. A live preview appears with the framing guide and lighting advisory.
5. The capture control becomes active after initialization.
6. The captured JPEG is held in memory and opened in the review screen.
7. Review validation and the existing upload repository continue unchanged.

## Acceptance Criteria

- [x] Camera screen uses a real `CameraController` and `CameraPreview`.
- [x] Camera initialization handles no-camera and initialization-error states visibly.
- [x] Captured images are passed to review as in-memory bytes.
- [x] Framing guide remains overlaid on top of the live preview.
- [x] Lighting advisory remains visible over the live preview.
- [x] Capture cannot be duplicated while a capture is in progress.
- [x] Camera controller is disposed when the screen closes.
- [ ] Real-time luminance sampling is not implemented yet; the current lighting message is advisory UI.
- [ ] Camera focus/exposure status indicators are not exposed by the current screen yet.
- [ ] Physical camera verification is required on a camera-capable browser/device.

## Platform Setup

### Web / Edge

Run a full restart after adding the plugin so Flutter registers the web implementation:

```powershell
flutter clean
flutter pub get
flutter run -d edge
```

The browser must grant camera permission when prompted. Use `localhost` or a secure origin; browser camera APIs may be blocked on an insecure or restricted origin.

### Android

Camera permission is required in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### iOS

Add `NSCameraUsageDescription` to `ios/Runner/Info.plist` with a clinician-facing explanation before running on iOS.

## Verification

- `flutter test test/widget_test.dart`
- `flutter analyze`
- Full manual verification: open a patient, choose **New analysis**, choose **Take photo**, grant camera permission, confirm live preview, confirm guide overlay, capture, and verify the review screen.

## Known Boundary

The camera package supplies the live preview and capture path. Lightweight luminance analysis and camera-reported focus/exposure indicators remain a follow-up because the current implementation intentionally keeps the existing advisory overlay and does not perform client-side quality scoring.
