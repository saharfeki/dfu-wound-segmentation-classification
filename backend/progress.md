## Backend update: `POST /analyses`

### Overview

The backend now accepts a multipart analysis creation request, stores the uploaded
image, creates a pending analysis record, and returns the generated analysis ID.

### Problems found

- `main.py` imported a nonexistent `app` package even though this workspace runs
	from the `backend` directory with `api` and `services` as top-level packages.
- `main.py` imported `analyses`, but only the processing router in `analyse.py`
	existed.
- The processing router referenced the undefined `get_current_clinician`, which
	prevented the router from importing.
- The required `POST /analyses` route had not been implemented.

### Solution

- Added `api/analyses.py` with `POST /analyses` using `patient_id`, `source`, and
	`image` multipart fields.
- Uploaded images to `raw/{patient_id}/{analysis_id}/original.jpg` or `.png`.
- Created the database row with status `pending` and returned
	`{"analysis_id": "...", "status": "pending"}`.
- Registered both the creation and processing routers in `main.py`.
- Updated imports to match the current backend layout and removed the undefined
	auth dependency from `/process`.

### Verification

The app imports successfully with `venv\\Scripts\\python.exe`, and both routes
are registered. The model-loading lifespan is intentionally not started during
the import check.

## Flutter processing flow

### Update

- Added `AnalysisResult` and a `process` operation to the Flutter analysis
	repository contract.
- `ApiAnalysisRepository` now posts to
	`/analyses/{analysisId}/process` after upload completion.
- `ImageReviewScreen` opens `AnalysisResultsScreen` with the processing response
	instead of returning directly to the patient workspace.
- Added a demo processing response so the non-API app mode follows the same flow.

### Verification

- `flutter analyze`: passed.
- `flutter test`: all tests passed.
- Live backend processing returned `complete` with a Grade 2 classification for
	the uploaded test image.
