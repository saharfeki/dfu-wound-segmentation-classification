# Feature 2b: Upload Path — Backend Wiring (FastAPI + S3)

## Overview
Replace the in-memory `DemoAnalysisRepository` with a real implementation that uploads the reviewed image to a FastAPI endpoint, which stores the raw file in S3 and creates the corresponding `analyses` record in Postgres. This closes the loop from "pending upload state" to an actual persisted analysis ready for Feature 3 (AI pipeline).

## Stack
- **Backend**: FastAPI, `boto3` for S3, `asyncpg`/SQLAlchemy for Postgres
- **Storage**: AWS S3 (or S3-compatible — Supabase Storage is also viable here since you're already on Supabase; worth considering to avoid a second cloud provider)
- **Client**: Flutter, `http`/`dio` package for multipart upload

## Backend

### Endpoint: `POST /analyses`
- **Auth**: requires valid Supabase JWT in `Authorization: Bearer` header; reject with 401 if missing/invalid/expired
- **Request**: `multipart/form-data`
  - `patient_id`: uuid (form field)
  - `source`: `camera` | `upload` (form field)
  - `image`: file (JPEG/PNG)
- **Server-side validation** (never trust client checks alone):
  - Content-Type must be `image/jpeg` or `image/png`
  - File size ≤ 15 MB (reject with 413 if exceeded)
  - Resolution ≥ 400×400 (decode header/dimensions server-side, reject with 422 and a clear message if too small)
  - `patient_id` must exist and be accessible to the authenticated clinician (single-clinic demo: any authenticated clinician; RLS still applies at the DB layer)
- **Processing**:
  1. Generate `analysis_id` (uuid)
  2. Upload raw file to storage under `raw/{patient_id}/{analysis_id}/original.{ext}`
  3. Insert `analyses` row: `status = 'pending'`
  4. Return `201` with `{analysis_id, status: "pending", created_at}`
- **Error responses**:
  - `400` — malformed request (missing fields)
  - `401` — invalid/missing auth
  - `404` — patient_id not found
  - `413` — file too large
  - `422` — invalid file type or resolution too low
  - `500` — storage/DB failure (log internally, return generic message to client)

### Data Model (Postgres) — as previously defined
```sql
create table analyses (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id),
  created_by uuid not null references clinicians(id),
  source text not null,
  raw_image_path text not null,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create index idx_analyses_patient_id on analyses(patient_id);

alter table analyses enable row level security;

create policy "analyses_read_all" on analyses
  for select using (auth.role() = 'authenticated');

create policy "analyses_insert_own" on analyses
  for insert with check (auth.uid() = created_by);
```

### FastAPI route sketch
```python
from fastapi import APIRouter, UploadFile, Form, Depends, HTTPException
from uuid import UUID, uuid4

router = APIRouter()

ALLOWED_TYPES = {"image/jpeg", "image/png"}
MAX_SIZE_BYTES = 15 * 1024 * 1024
MIN_DIMENSION = 400

@router.post("/analyses", status_code=201)
async def create_analysis(
    patient_id: UUID = Form(...),
    source: str = Form(...),
    image: UploadFile = ...,
    clinician_id: UUID = Depends(get_current_clinician),  # from JWT middleware
):
    if image.content_type not in ALLOWED_TYPES:
        raise HTTPException(422, "Unsupported file type")

    contents = await image.read()
    if len(contents) > MAX_SIZE_BYTES:
        raise HTTPException(413, "File exceeds 15 MB limit")

    width, height = get_image_dimensions(contents)  # e.g. via Pillow
    if width < MIN_DIMENSION or height < MIN_DIMENSION:
        raise HTTPException(422, "Image resolution too low")

    patient = await get_patient(patient_id)
    if not patient:
        raise HTTPException(404, "Patient not found")

    analysis_id = uuid4()
    ext = "jpg" if image.content_type == "image/jpeg" else "png"
    storage_key = f"raw/{patient_id}/{analysis_id}/original.{ext}"
    await upload_to_storage(storage_key, contents, content_type=image.content_type)

    await create_analysis_row(
        id=analysis_id,
        patient_id=patient_id,
        created_by=clinician_id,
        source=source,
        raw_image_path=storage_key,
        status="pending",
    )

    return {"analysis_id": str(analysis_id), "status": "pending"}
```

## Flutter Client

### `AnalysisRepository` — real implementation
Same interface as the demo adapter, swapped in behind the existing abstraction — no changes needed to the Review screen or navigation logic that calls it.

```dart
abstract class AnalysisRepository {
  Future<Analysis> createAnalysis({
    required String patientId,
    required Uint8List imageBytes,
    required String filename,
    required AnalysisSource source,
  });
}

class ApiAnalysisRepository implements AnalysisRepository {
  final Dio _dio;
  final String Function() _getAccessToken;

  ApiAnalysisRepository(this._dio, this._getAccessToken);

  @override
  Future<Analysis> createAnalysis({
    required String patientId,
    required Uint8List imageBytes,
    required String filename,
    required AnalysisSource source,
  }) async {
    final formData = FormData.fromMap({
      'patient_id': patientId,
      'source': source.name,
      'image': MultipartFile.fromBytes(imageBytes, filename: filename),
    });

    try {
      final response = await _dio.post(
        '/analyses',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer ${_getAccessToken()}'},
        ),
        onSendProgress: (sent, total) {
          // surface to an upload-progress stream/notifier
        },
      );
      return Analysis.fromJson(response.data);
    } on DioException catch (e) {
      throw AnalysisUploadException(_mapError(e));
    }
  }

  String _mapError(DioException e) {
    switch (e.response?.statusCode) {
      case 401: return 'Session expired — please sign in again.';
      case 413: return 'Image is too large (max 15 MB).';
      case 422: return 'Image type or resolution not supported.';
      case 404: return 'Patient record not found.';
      default: return 'Upload failed — please try again.';
    }
  }
}
```

### Upload progress UI
- Reuse the existing pending-upload state screen; bind it to `onSendProgress` to show a real percentage instead of an indeterminate spinner
- On success: navigate to Feature 3's processing screen with the returned `analysis_id`
- On failure: show `AnalysisUploadException.message` inline with a "Retry" button that re-invokes `createAnalysis` with the same in-memory bytes (no need to re-pick/re-capture)

## Acceptance Criteria
- [ ] Selecting/capturing an image and tapping Continue sends a real multipart request to `POST /analyses`
- [ ] A valid JWT is attached to every request; expired/missing tokens surface a clear "session expired" message and route back to Login
- [ ] Server-side validation independently enforces type/size/resolution, even if client checks are bypassed
- [ ] Successful upload creates a persisted `analyses` row with `status = 'pending'` and a real S3/Storage object
- [ ] Client receives and stores `analysis_id`, using it to navigate to Feature 3
- [ ] Upload progress is visibly reflected in the UI (percentage or progress bar, not just a static spinner)
- [ ] Network failures and server error responses (401/404/413/422/500) each show a distinct, clear message with a retry option
- [ ] Swapping `DemoAnalysisRepository` → `ApiAnalysisRepository` requires no changes to Review screen or navigation code

## Open Question
- S3 vs Supabase Storage for raw image storage — since you're already on Supabase for Auth+DB, using Supabase Storage instead of AWS S3 avoids a second cloud account/credential set for a thesis demo. Worth switching unless you have a specific reason to keep AWS S3 (e.g. a lab requirement).