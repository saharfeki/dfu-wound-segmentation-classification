Progress Tracker
Update this file after every meaningful implementation change.

## Current Phase

- Feature 4 guided camera viewfinder: real camera client in progress

## Current Goal

- Replace the mocked camera surface with a real preview and capture flow while preserving review/upload behavior.

## Completed

- Replaced the stock counter app with the MedConnect trusted-clinic-blue theme.
- Added login screen with email/password validation and signed-in session transition.
- Added patient list with name/external-reference search and patient cards.
- Added new-patient form with required full name and optional patient ID.
- Added logout action and focused widget coverage for valid and invalid login input.
- Added patient detail entry point with a New Analysis action.
- Added Take Photo and Upload from Files choice screen using `image_picker`.
- Added guided camera surface with advisory lighting/framing feedback and always-enabled capture.
- Added in-memory image review with JPEG/PNG, 15 MB, and 400x400 resolution validation.
- Added pending upload state through an `AnalysisRepository` demo adapter and navigation back to the patient workspace.
- Added `ApiAnalysisRepository` using Dio multipart upload to `/analyses`.
- Added bearer-token injection, source/patient form fields, response parsing, and status-specific upload errors.
- Added visible upload percentage/progress state and retry behavior using the same in-memory image.
- Added build-time `API_BASE_URL` and `SUPABASE_ACCESS_TOKEN` selection while retaining the demo adapter when no API URL is configured.
- Replaced the upload branch's gallery-based picker with `file_picker`, explicitly filtering JPEG/PNG files and retaining selected bytes in memory.
- Added user-facing handling when a selected file cannot be opened or read.
- Fixed Edge/Web file-picker activation by invoking `pickFiles()` synchronously inside the upload tile's click handler; selected-file processing now runs after the picker future resolves.
- Added the `camera` package and replaced the placeholder guided-camera icon with a real `CameraController` and `CameraPreview`.
- Added camera initialization, no-camera/error states, lifecycle disposal, and duplicate-capture protection.
- Captured camera images now use `CameraController.takePicture()` and continue to the existing in-memory review/upload flow.
- Documented Feature 4 implementation, acceptance status, platform setup, and known feedback boundaries in `contextDFU/features/4-camera.md`.

## In Progress

- The Flutter client is ready for the endpoint, but this workspace contains no FastAPI service, database schema, storage configuration, or live Supabase token provider.
- File selection now uses the desktop/web-friendly file picker; live device/browser verification still depends on the target platform's file chooser.
- Real camera verification still requires a camera-capable browser/device and granted camera permission.

## Next Up

- Add `supabase_flutter` initialization and replace `DemoRepository` with Supabase Auth/session persistence.
- Add the FastAPI `/patients` routes and connect patient list/create/search to authenticated requests.
- Implement the FastAPI `/analyses` route, server-side validation, storage upload, and `analyses` insert in the backend workspace.
- Provide a runtime Supabase session token callback instead of the build-time token placeholder.
- Connect the guided camera surface to a live `camera` preview and platform focus/exposure state.
- Add camera luminance sampling and camera-reported focus/exposure indicators after validating platform API support.
- Add patient detail/history navigation in Feature 6.

## Open Questions

- Should Stage A and Stage B model weights be loaded into GPU memory at server boot, or managed dynamically via ONNX Runtime execution providers?
- What exact Wagner Grade scale format (Grades 0–5 vs. Texas Wound Classification) will Stage C output in its pre-formulated response payload?
- Is local offline caching required for the web client, or will offline-first image analysis be limited exclusively to the Flutter mobile application?

## Architecture Decisions

- **Server-Side 3-Model Cascade Architecture**: Consolidated model execution to the backend (Stage A 3ch mask $\rightarrow$ Stage B 4ch refinement $\rightarrow$ Stage C ROI crop classification). **Why**: Reduces mobile payload size, keeps proprietary model weights secure, and prevents device hardware performance bottlenecks on lower-end mobile devices.
- **Single Stage B Visual Mask Return**: Stage A output remains entirely in-memory on the backend and is never sent to the client; only Stage B's refined mask is returned. **Why**: Keeps client-side state clean and eliminates unnecessary bandwidth consumption while presenting the highest-accuracy boundary to the user.
- **ROI Bounding Box Transparency**: Returned Stage C classification results include the precise bounding box coordinates extracted from Stage B. **Why**: Enables the Flutter UI to display the exact cropped region used for grading, ensuring clinical transparency for why a specific ulcer grade was assigned.
- **Clinician-Centric Light Theme**: Standardized UI design system on "Trusted Clinic Blue" (`#2D60DB`) with rounded card/button surfaces (`16px`/`24px`). **Why**: Ensures maximum readability and visual comfort in bright clinical environments while matching modern medical app UX standards.

## Session Notes

- Project context, system boundaries, and UI context ("Trusted Clinic Blue" theme) have been finalized.
- Started Feature 1 with a local Flutter vertical slice. The Supabase/API boundary is intentionally isolated behind `PatientRepository` so the UI can be validated before backend credentials and routes exist.
- Started Feature 2 with a local Flutter acquisition slice. `AnalysisRepository` isolates the future FastAPI/S3 upload, while selected image bytes remain in memory until submission succeeds.
- Implemented Feature 2b on the client. The API adapter is selected with `--dart-define=API_BASE_URL=...`; until that is supplied, the app remains runnable with the demo adapter. `SUPABASE_ACCESS_TOKEN` is temporary until Supabase Auth session wiring is added.
- Implemented Feature 4's real camera preview and capture path. The guide and lighting message remain advisory overlays; luminance sampling and focus/exposure indicators are explicitly tracked as follow-up work.