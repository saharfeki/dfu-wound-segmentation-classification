Progress Tracker
Update this file after every meaningful implementation change.

## Current Phase

- Not started

## Current Goal

- Initial repository setup, Flutter environment configuration, and backend FastAPI scaffold for the 3-model AI cascade.

## Completed

- None yet.

## In Progress

- Initial repository scaffold and environment configuration.

## Next Up

- Set up Flutter application skeleton with the MedConnect blue-wave theme tokens, routing, and custom camera module with lighting/focus feedback.
- Build basic FastAPI backend scaffold with endpoint routing for `/api/v1/analyze-ulcer`.

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
- Start the next session by initializing the Flutter project (`lib/`) and FastAPI server (`app/`), focusing first on setting up the custom camera view with real-time feedback and setting up mock endpoints for the inference pipeline.