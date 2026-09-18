Progress Tracker
Update this file after every meaningful implementation change.

## Current Phase

- Feature 1 authentication and patient context: client foundation in progress

## Current Goal

- Deliver the first usable authentication and patient-context slice in Flutter.

## Completed

- Replaced the stock counter app with the MedConnect trusted-clinic-blue theme.
- Added login screen with email/password validation and signed-in session transition.
- Added patient list with name/external-reference search and patient cards.
- Added new-patient form with required full name and optional patient ID.
- Added logout action and focused widget coverage for valid and invalid login input.

## In Progress

- Supabase Auth and FastAPI patient endpoints still need wiring; the current repository is an in-memory demo adapter.

## Next Up

- Add `supabase_flutter` initialization and replace `DemoRepository` with Supabase Auth/session persistence.
- Add the FastAPI `/patients` routes and connect patient list/create/search to authenticated requests.
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