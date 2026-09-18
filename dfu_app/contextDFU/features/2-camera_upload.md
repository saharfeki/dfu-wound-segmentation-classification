# Feature 2: Photo Acquisition (Camera + Upload)

## Overview
From a patient's detail screen, the clinician starts a new analysis by providing a photo of the ulcer — either captured live via a guided camera viewfinder or uploaded from an existing file (gallery/local drive). Both paths converge into the same client-side validation and upload flow before reaching the AI pipeline (Feature 3).

## Stack
- **Client**: Flutter (mobile + web), using `camera` (or `image_picker` for a lighter cross-platform wrapper), `image_picker` for file/gallery selection
- **Backend**: FastAPI, receives multipart image upload
- **Storage**: AWS S3 (raw image), path recorded in Postgres against the analysis record

## User Flow
1. From Patient Detail screen, clinician taps "New Analysis"
2. Entry point choice screen: **"Take Photo"** or **"Upload from Files"**
3a. **Take Photo path**: guided camera viewfinder opens → live feedback on lighting/focus/distance → capture → review screen (retake or continue)
3b. **Upload path**: native file/gallery picker opens → clinician selects an image → review screen (choose different file or continue)
4. Review screen shows the selected image full-size, with "Continue" (proceeds to preprocessing/upload) and "Retake"/"Choose Different" actions
5. On "Continue": client runs local validation (file type, size, resolution) → shows upload progress → on success, navigates to Feature 3 (AI processing/loading state)

## Guided Camera Viewfinder — Feedback Logic
Real-time overlay feedback rendered on the camera preview, using frame-sampling (not full inference — lightweight heuristics only, since actual quality validation happens server-side or via basic client checks):
- **Lighting**: sample average luminance of the frame; if too dark/bright, show a warning banner ("Move to better light")
- **Focus**: use platform camera APIs' built-in focus/exposure lock rather than reimplementing blur detection in Dart; show a green/red focus indicator ring based on camera-reported focus state
- **Distance/framing**: show a fixed on-screen guide overlay (e.g. a translucent circle/rectangle) instructing the clinician to fill the guide with the wound area — this is a static UI aid, not computed from the frame
- Capture button remains enabled regardless of feedback state (feedback is advisory, never blocking — a clinician must always be able to capture in non-ideal conditions)

## Client-Side Validation (before upload)
- **File type**: JPEG or PNG only
- **File size**: max 15 MB (adjust to your infra limits)
- **Minimum resolution**: reject images below a defined floor (e.g. 400×400px) with a clear message ("Image resolution too low — please retake or choose a larger photo")
- No client-side blur/quality scoring in v1 — flagged as a possible future enhancement (see Open Questions)

## Backend (FastAPI)

### Endpoint
`POST /analyses` (multipart/form-data)
- Fields: `patient_id` (uuid), `image` (file), `source` (`camera` | `upload`)
- Validates: JWT auth, patient exists and clinician has access, file type/size server-side (never trust client-side checks alone)
- Uploads raw image to S3 under `raw/{patient_id}/{analysis_id}/original.jpg`
- Creates an `analyses` row with status `pending` (before Stage A/B/C run — see Feature 3)
- Returns `{analysis_id, status: "pending"}` immediately; client polls or awaits a follow-up call to kick off Feature 3's inference

### Data Model (Postgres)
```sql
create table analyses (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references patients(id),
  created_by uuid not null references clinicians(id),
  source text not null, -- 'camera' | 'upload'
  raw_image_path text not null, -- S3 key
  status text not null default 'pending', -- 'pending' | 'processing' | 'complete' | 'failed'
  created_at timestamptz not null default now()
);

create index idx_analyses_patient_id on analyses(patient_id);
```

### RLS
```sql
alter table analyses enable row level security;

create policy "analyses_read_all" on analyses
  for select using (auth.role() = 'authenticated');

create policy "analyses_insert_own" on analyses
  for insert with check (auth.uid() = created_by);
```

## Flutter Client

### Screens
1. **New Analysis entry screen** — two large buttons: "Take Photo" / "Upload from Files", triggered from Patient Detail
2. **Camera Capture screen** — live preview, guide overlay, lighting warning banner, capture button, focus indicator
3. **Review screen** — shows selected/captured image, "Retake"/"Choose Different" and "Continue" actions
4. **Upload progress state** — simple progress indicator while `POST /analyses` is in flight; on success, navigate to Feature 3's processing/loading screen; on failure, show retry option with the error message

### State handling
- Selected image held in memory (bytes) until upload confirmed — nothing written to local Isar/SQLite until the analysis record is confirmed created server-side (keeps local history in sync with what's actually persisted)
- `AnalysisRepository` abstraction (mirroring Feature 1's `PatientRepository` pattern) — isolate the S3/FastAPI upload call behind an interface so the UI can be built/tested before the backend endpoint exists, consistent with your current DemoRepository approach

## Acceptance Criteria
- [ ] Clinician can choose "Take Photo" or "Upload from Files" from New Analysis screen
- [ ] Camera preview shows live lighting feedback and a framing guide overlay
- [ ] Capture button is always enabled, never blocked by feedback state
- [ ] File picker restricts selectable types to JPEG/PNG where the platform allows it
- [ ] Client rejects files over the size limit or below minimum resolution, with a clear inline message
- [ ] Review screen allows retake/reselect before committing to upload
- [ ] Successful upload creates an `analyses` row with status `pending` and returns an `analysis_id`
- [ ] Upload failures (network, server validation) show a clear error with a retry action, no silent failures
- [ ] `POST /analyses` rejects requests with missing/invalid JWT (401) or a patient_id the clinician can't access

## Out of Scope for v1
- Client-side blur/quality scoring beyond basic resolution/size checks
- Multi-image capture per analysis (v1 is single image in, single image out)
- Resumable/chunked upload for large files or poor connectivity