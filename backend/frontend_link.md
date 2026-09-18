## Frontend and Backend Integration Summary

### Local Edge Instructions

Uvicorn is configured for plain HTTP during local development. Start it from
the `backend` directory:

```powershell
.\venv\Scripts\python.exe -m uvicorn main.main:app --host 0.0.0.0 --port 8000
```

Check the backend in Edge at `http://127.0.0.1:8000/` or
`http://127.0.0.1:8000/docs`. Do not use `https://` unless TLS certificates
have been configured for Uvicorn.

Run Flutter web with the local API URL:

```powershell
flutter run -d edge --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### Browser Health Endpoint

The backend now includes a health check endpoint at `/` that returns the status of the service.

### Upload flow

The Flutter app uploads a wound image through `ApiAnalysisRepository`:

```text
POST /analyses
Content-Type: multipart/form-data

patient_id: <patient ID>
source: camera | upload
image: <JPEG or PNG file>
```

The backend stores the original image, creates a pending analysis record, and
returns:

```json
{
	"analysis_id": "<UUID>",
	"status": "pending"
}
```

### Processing flow

After the upload confirmation dialog is closed, Flutter calls:

```text
POST /analyses/<analysis_id>/process
```

The processing response is passed to `AnalysisResultsScreen` instead of sending
the user directly back to the patient workspace. The results screen displays the
analysis status, fallback state, grade, classification status, and clinical
message when available.

Example successful response:

```json
{
	"analysis_id": "<UUID>",
	"status": "complete",
	"fell_back": false,
	"mask_url": "masks/<patient_id>/<analysis_id>/mask.png",
	"bbox": [115, 0, 470, 286],
	"grade": 2,
	"classification_status": "CONFIDENT",
	"message": "Predicted Grade 2 (Granulation) -> Recommended dressing: Hydrocolloid"
}
```

### Files involved

- `backend/api/analyses.py`: creates the analysis and stores the original image.
- `backend/api/analyse.py`: processes the uploaded analysis.
- `backend/main/main.py`: registers both API routers.
- `dfu_app/lib/main.dart`: uploads, processes, and displays results.

### Verification

- `flutter analyze`: passed.
- `flutter test`: all tests passed.
- Live `POST /analyses` upload returned `200 OK` with a pending analysis ID.
- Live process request returned `complete` with a confident Grade 2 result.
