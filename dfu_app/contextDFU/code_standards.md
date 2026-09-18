# Code Standards

## General

- Keep modules small, single-purpose, and decoupled across client and server logic.
- Fix root causes in model pipelines and UI flows rather than layering patch workarounds.
- Do not mix unrelated concerns (e.g., camera hardware capture with AI payload serialization).

## Dart & Flutter

- Enforce strict linter rules via `flutter_lints`; no implicit `dynamic` types without explicit runtime casting.
- Prefer immutable `StatelessWidget` and custom hooks (`flutter_hooks`) over deeply nested `StatefulWidget` instances.
- Handle state using structured state management (e.g., `flutter_riverpod`) with explicit state loading/error handling union types.

## Python & FastAPI

- Enable strict typing across all backend services; use `Pydantic` v2 models for schema enforcement.
- Rely on asynchronous execution (`async`/`await`) for route handlers and non-blocking I/O operations.
- Isolate heavy ML inference loops into dedicated service modules using `onnxruntime` or `torch` wrappers.

## Styling & Design System

- Use central CSS variable tokens on Web and `ThemeData` tokens in Flutter—no hardcoded hex values in code.
- Apply the defined corner radius tokens (`10px` inputs, `16px` cards, `24px` primary buttons).
- Enforce the "Trusted Clinic Blue" palette (`#2D60DB`) for all primary actions and structural wave headers.

## API & Inference Endpoints

- Validate image upload format, dimensions, and byte sizes via `Pydantic` before sending data to the AI pipeline.
- Authenticate requests via Bearer JWT middleware before processing or retrieving patient records.
- Return standardized API response shapes containing Stage B mask metadata, Stage C ROI bounding boxes, classification scores, and recommendation strings.

## Data and Storage

- Keep structured data (patient details, assessment metadata, classification scores) strictly inside PostgreSQL.
- Store raw ulcer photos, Stage B binary mask PNGs, and ROI crops exclusively in S3 blob storage.
- Never write intermediate binary outputs (like Stage A masks) to disk; process them strictly in-memory.

## File Organization

- `lib/` — Flutter client application (UI widgets, camera controllers, state providers, and platform channels).
- `app/api/` — FastAPI endpoint routers, authentication middleware, and request/response schema validators.
- `app/services/` — Core business logic, storage handlers, and the 3-model AI cascade orchestration.
- `app/models/` — Pydantic schema definitions and ONNX/PyTorch model loading routines.