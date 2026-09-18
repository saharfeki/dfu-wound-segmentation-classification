# Diabetic Foot Ulcer (DFU) AI Analysis System

## Overview

This application is a specialized cross-platform digital health platform designed for healthcare professionals, podiatrists, and clinical researchers to automate diabetic foot ulcer (DFU) assessment. By combining on-device computer vision with web accessibility, the system streamlines the clinical workflow: users capture or upload an image of a foot ulcer, receive precise pixel-level lesion segmentation, and get instant severity/tissue classification. This automated approach replaces subjective visual estimates with reproducible data, aiding early intervention and reducing lower-limb amputation risks in diabetic patients.

## Goals

1. High-Precision Segmentation: Achieve a Mean Intersection over Union (mIoU) ≥ 0.85 and a Dice Similarity Coefficient ≥ 0.88 on the server-side segmentation cascade (Stage A + Stage B) across varied skin tones and lighting conditions.

2. **Sub-3-Second Pipeline Latency**: Deliver end-to-end processing (image preprocessing, dual-model inference, and visual rendering) within 3 seconds on standard mid-tier smartphones and web browsers.

3. **Clinical Classification Accuracy**: Reach $\ge 90\%$ classification accuracy (e.g., Wagner scale or tissue type classification like necrotic, granulation, slough) across standard evaluation datasets.

## Core User Flow

1. **Authentication & Patient Context**: The clinician signs in and selects an existing patient record or creates a new entry.

2. **Image Capture/Upload**: The user captures a foot ulcer image via the Flutter camera module (with overlay alignment guides) or uploads a high-resolution photo from the gallery/web drive.

3. **Preprocessing Pipeline**: The system automatically executes automated cropping, quality check (blur/exposure detection), normalization, and tensor conversion.

4. **AI Inference Stage 1 (Segmentation)**: The segmentation model generates a binary/multi-class mask identifying the precise boundary and area of the ulcer tissue.

5. **AI Inference Stage 2 (Classification)**: The region of interest (ROI) is passed to the classification model to grade severity or identify primary tissue composition.

6. **Result Review & Overlay Visualization**: The screen displays the original photo with an interactive segmentation mask overlay, calculated surface area/metrics, and the classification result.

7. **Export & Storage**: The user verifies the diagnostic output, adds clinical notes, and saves the report to the local device database or syncs it to the cloud database.

## Features

### Image Acquisition & Preprocessing

- **Guided Camera Integration**: Custom camera viewfinder with real-time feedback on lighting, focus, and distance to standardize photo collection.

- **Automated Image Pipeline**: In-memory resizing ($512 \times 512$), pixel color normalization, and tensor transformation tailored for TensorFlow Lite/ONNX runtimes.

- **Data Augmentation Preview**: Internal processing hooks for contrast enhancement (CLAHE) to boost boundary definition before model ingestion.

### Dual-Model AI Engine

:**1. Image Acquisition & Preprocessing**

- Guided camera viewfinder (lighting/focus/distance feedback)
- Client-side resize + compression before upload


**2. Dual-Model AI Engine → now a 3-model server-side cascade**

- Stage A (3ch mask model) and Stage B (4ch refinement model) run sequentially on the backend, invisible to the app — only Stage B's mask is returned
- Stage C classifier runs on the auto-cropped wound region, returns grade + probabilities + the full recommendation message text as-is

**3. Mask Overlay Visualizer**

- Renders Stage B mask only, toggleable opacity/visibility over the original photo
- No bbox/polygon toggle needed unless you want to show the crop region used for classification (worth showing, since it explains *what the classifier actually saw* — otherwise a user might wonder why the grade came from what looks like the whole image)

**4. Results Display**

- Show `message` from `predict_and_recommend` verbatim as the primary result (this is presumably already phrased as a clinical recommendation)
- Show `class_probabilities` as a secondary confidence breakdown (e.g. small bar chart or expandable detail) — worth keeping even though the message is primary, so a clinician can see how confident the model was, especially for borderline/adjacent-grade cases which you noted are your main error mode

### Cross-Platform UI & Analytics (Flutter & Web)

- **Responsive Web & Mobile Dashboards**: Shared UI codebase supporting touch interaction on mobile and desktop layout controls on web browsers.

- **Historical Tracking**: Patient history timeline with side-by-side visual comparisons of segmentation masks to track wound healing progress over time.

- **Report Generation**: Export analysis summaries (segmented images, classification confidence, area metrics, timestamps) to PDF format.

## Scope

### In Scope

- Flutter mobile (Android/iOS) and Flutter Web client applications.
Integrated 3-stage AI inference cascade (Stage A mask → Stage B refinement → Stage C classification) running server-side via FastAPI + ONNX Runtime/PyTorch, invoked over authenticated REST calls from the Flutter client (mobile + web).
- Pixel-level image segmentation and multi-class ulcer grading classification.
- Interactive mask rendering with adjustable opacity controls.
- Local SQLite/Isar database storage for offline history and optional RESTful sync to a back-end.

### Out of Scope

- Direct hardware calibration using 3D depth-sensing hardware (LiDAR/Structured Light) in v1.
- Direct Electronic Health Record (EHR) integration via FHIR protocols (planned for v2).
- Automatic prescribing or automated medical treatment recommendations.
-On-device/offline AI inference — the segmentation and classification models run server-side only in v1; a distilled/quantized on-device pipeline is a possible v2 stretch goal.

## Success Criteria

1. **End-to-End Execution**: A user can upload an image on either mobile or web, execute the dual-model pipeline, and view the visual segmentation mask along with classification outputs within 3 seconds.

2. **Cross-Platform Parity**: Model inference outputs (segmentation masks and confidence scores) maintain consistent performance metrics on both Android/iOS devices and Web browsers.

3. Offline History Access: Previously synced patient reports (original image, mask overlay, classification result) remain viewable on-device without connectivity via local SQLite/Isar cache. Live image acquisition and AI inference require an active connection to the backend.