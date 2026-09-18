## Frontend/backend connection issue

### Symptom

Running only the Flutter command and uploading an image showed:

> Upload failed - check your connection and try again.

The Flutter client was correctly configured to send `POST /analyses` to
`http://127.0.0.1:8000`, but no process was listening on that port. The model
files were present and load successfully on CPU; the failure happened before
the request reached the backend.

### Correct startup order

Open a terminal in the `dfu_app` workspace folder:

```powershell
..\backend\venv\Scripts\python.exe -m uvicorn --app-dir ..\backend main.main:app --host 127.0.0.1 --port 8000
```

Alternatively, run the VS Code task named `Start DFU backend`.

Keep that terminal running. Verify the service before opening Flutter:

```powershell
Invoke-WebRequest http://127.0.0.1:8000/
```

The response must contain `{"status":"ok","service":"dfu-wound-api"}`.

Do not open `https://127.0.0.1:8000` in the browser. This local Uvicorn
server does not use TLS; the health URL is `http://127.0.0.1:8000/`.

Then run the web client in a second terminal:

```powershell
cd C:\Users\User\Desktop\dfu-wound-segmentation-classification\dfu_app
flutter run -d edge --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Do not use `https://` for this local Uvicorn server. `127.0.0.1` is correct
when Edge and the backend run on the same computer.

### Request and model flow

1. Flutter sends `multipart/form-data` to `POST /analyses` with `patient_id`,
	 `source`, and a JPEG/PNG `image`.
2. The backend stores the original image in `backend/storage/` and returns an
	 analysis ID with status `pending`.
3. Flutter sends `POST /analyses/{analysis_id}/process`.
4. The backend downloads the stored image, runs Stage A segmentation, Stage B
	 refinement, and Stage C classification, then returns the mask path, box,
	 grade, confidence status, and recommendation message.
5. The results screen keeps the uploaded image in memory and layers the
	backend's transparent red Stage B overlay over it. The overlay is served
	from `/storage/.../overlay.png` so Edge can load it through the API.

The three checkpoints are loaded once when Uvicorn starts:

- `backend/models/best_model_bg_remove.pth`
- `backend/models/unet_improved.pth`
- `backend/models/best_model_classification.pth`

### Fixes applied

- Added explicit validation for `source` and rejected unsupported upload MIME
	types instead of treating arbitrary files as PNG images.
- Kept the Flutter route and field names aligned with the FastAPI routes.
- Changed Flutter's connection error message to identify an unreachable
	backend and show the configured API URL.
- Confirmed all three model checkpoints load successfully on CPU.
- Added a transparent red segmentation overlay and displayed it over the
	original uploaded image on the Flutter results screen.

### Common causes

- Backend terminal was not started, or it exited while loading dependencies.
- Port 8000 was already occupied by another process.
- Flutter was started with a different `API_BASE_URL` than the Uvicorn port.
- The selected file was not a JPEG/PNG, or the request was sent without the
	required multipart fields.
