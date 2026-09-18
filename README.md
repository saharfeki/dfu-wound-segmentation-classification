# MedConnect: DFU Detect

### AI-Powered Diabetic Foot Ulcer Assessment

MedConnect: DFU Detect is a cross-platform healthcare application for **image-based diabetic foot ulcer (DFU) assessment**. The platform combines a Flutter mobile interface with a deep learning pipeline for wound segmentation, severity classification, and confidence-based clinical decision support.

The system is designed to support **clinicians, researchers, and healthcare teams** by providing a fast and intuitive workflow for acquiring wound images, processing them with AI models, and presenting clinically relevant assessment results.

> **Important:** DFU Detect is a research and clinical decision-support prototype. Its outputs are intended to assist healthcare professionals and should not be considered a standalone medical diagnosis.

[![Flutter](https://img.shields.io/badge/Flutter-3.13.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Python](https://img.shields.io/badge/Python-3.x-3776AB?logo=python)](https://www.python.org/)
[![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-F37626?logo=jupyter)](https://jupyter.org/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-4CAF50)](https://flutter.dev)
[![Status](https://img.shields.io/badge/Status-Research%20Prototype-FFA000)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Overview

DFU Detect brings together a **mobile-first healthcare interface** and an **AI-powered wound assessment pipeline**.

The application allows users to:

- Capture wound images using a device camera
- Upload existing clinical images
- Validate and prepare images for analysis
- Process images through an AI assessment pipeline
- Visualize wound segmentation results
- Predict DFU severity from Grade 1 to Grade 4
- Display prediction confidence and supporting information
- Provide a dressing recommendation when confidence requirements are met
- Flag uncertain cases for manual clinical review

The overall workflow is:

```text
Wound Image
     │
     ▼
Image Acquisition
(Camera / Upload)
     │
     ▼
Image Preparation
     │
     ▼
Wound Segmentation
(U-Net + ResNet34)
     │
     ▼
Wound Region Processing
     │
     ▼
Severity Classification
(ResNet50v2 + CORN)
     │
     ▼
Confidence Assessment
     │
     ├─────────────── High Confidence ──────────────► Dressing Recommendation
     │
     └─────────────── Low Confidence / Close Margin ► Manual Clinical Review
```

For a detailed description of the application interface and functionality, See the [main documentation](https://github.com/saharfeki/dfu-wound-segmentation-classification/blob/main/dfu_app/README.md) for more details.

---

# AI Assessment Pipeline

The AI component is maintained as the `dfu-wound-segmentation-classification` pipeline.

It provides an end-to-end research workflow covering:

1. **Wound Segmentation**
2. **Severity Classification**
3. **Confidence-Based Decision Support**

The pipeline transforms an RGB wound image into a severity assessment and, when appropriate, a grade-specific dressing recommendation.

---

## AI Pipeline Architecture

### 1. Wound Segmentation

The segmentation stage isolates the ulcer region from surrounding tissue.

Several deep learning architectures were evaluated using the **DFUC2022** dataset, including:

- FPN + ResNeXt50
- U-Net + ResNet34
- nnU-Net

The selected segmentation model is:

**U-Net + ResNet34**

with a final Dice score of **0.8241** on the evaluated validation setup.

The segmentation model provides a wound-region mask that can be used to support downstream image processing and visualization.

---

### 2. Severity Classification

The classification stage predicts DFU severity from **Grade 1 to Grade 4**.

| Grade | Clinical Description |
|---|---|
| Grade 1 | Superficial ulcer without infection |
| Grade 2 | Deep ulcer reaching tendon or capsule |
| Grade 3 | Deep ulcer with bone involvement |
| Grade 4 | Localized gangrene |

The final classification architecture uses:

- **Backbone:** ResNet50v2 (BiT)
- **Classification Head:** CORN ordinal regression
- **Input:** RGB wound image
- **Loss:** Class-weighted CORN loss
- **Optimization:** AdamW
- **Learning Strategy:** Discriminative learning rates and two-phase fine-tuning
- **Scheduling:** Cosine annealing
- **Augmentation:** Image augmentation and test-time augmentation
- **Refinement:** Classification threshold calibration

CORN ordinal regression was selected because DFU severity grades have an inherent order, allowing the model to account for the difference between adjacent and more distant severity levels.

---

## Model Selection

A segmentation-assisted classification approach using a four-channel input consisting of RGB information and the predicted wound mask was investigated.

The ablation study showed that the four-channel approach did not provide a measurable accuracy improvement over RGB-only classification. In addition, segmentation errors on unseen images could propagate into the classification stage.

As a result, the final severity classifier uses **RGB-only input**, while segmentation remains an independent component of the assessment and visualization workflow.

This design provides a simpler and more robust classification pathway while preserving the ability to display wound localization results.

---

# Results

## Segmentation

| Model | Dice Score | Training Time |
|---|---:|---:|
| FPN + ResNeXt50 | 0.8175 | ~3 hours |
| **U-Net + ResNet34** | **0.8241** | **~1 hour** |
| nnU-Net | 0.7526 | — |

**Selected model:** U-Net + ResNet34

---

## Severity Classification
### Classification 
| Stage | Accuracy | Macro F1 | MAE | QWK |
|---|---|---|---|---|
| Initial (RGB-only vs. 4-channel) | 56.7% | 54.6% / 55.1% | — | — |
| + Optimized training strategy | 61.7% | 59.3% | — | — |
| Intermediate final model | 75.3% | — | 0.291 | 0.813 |
| **Final model (after refinement)** | **80.64%** | **80.07%** | **0.209** | **0.888** |
The final classification model achieved the following results during evaluation:

| Metric | Final Result |
|---|---:|
| Accuracy | **80.64%** |
| Macro F1 | **80.07%** |
| MAE | **0.209** |
| QWK | **0.888** |

The Quadratic Weighted Kappa (QWK) of **0.888** indicates a high level of agreement between predicted and reference severity grades under the evaluated experimental setup.

---

## Decision Support

The decision-support layer combines the predicted severity, confidence score, and prediction margin.

```text
Prediction
    │
    ▼
Confidence Evaluation
    │
    ├── High Confidence
    │       │
    │       ▼
    │   Grade-Specific
    │   Recommendation
    │
    └── Low Confidence
            │
            ▼
      Manual Clinical Review
```

The evaluated high-confidence subset achieved **97.6% accuracy**, with uncertain cases automatically deferred for manual review.

This mechanism is intended to reduce the risk of presenting uncertain model predictions as definitive clinical recommendations.

---

# Datasets

The AI pipeline was developed using two datasets with different roles:

| Dataset | Purpose | Ground Truth |
|---|---|---|
| **DFUC2022** | Wound segmentation | Binary wound masks |
| **DFU Severity Grading Dataset** | Severity classification | Grade 1–4 labels |

The segmentation and classification tasks are therefore evaluated independently according to the available annotations.

---

# Repository Structure

The AI research notebooks are organized as follows:

```text
dfu-wound-segmentation-classification/
│
├── 01_unet_resnet34_nnunet_segmentation_classification.ipynb
├── 02_resnet50v2_corn_ordinal_full_pipeline.ipynb
│
└── README.md
```

### `01_unet_resnet34_nnunet_segmentation_classification.ipynb`

Contains the segmentation experiments and early classification studies.

It includes:

- Comparison of FPN + ResNeXt50 and U-Net + ResNet34
- nnU-Net evaluation
- Segmentation performance analysis
- Segmentation-assisted classification experiments
- RGB-only versus RGB + mask ablation study
- Model selection based on performance and computational cost

### `02_resnet50v2_corn_ordinal_full_pipeline.ipynb`

Contains the final classification and decision-support pipeline.

It includes:

- ResNet50v2-based severity classification
- CORN ordinal regression
- Class-weighted training
- Fine-tuning and optimization strategies
- Threshold calibration
- Confidence and prediction-margin analysis
- Dressing recommendation logic
- Manual-review fallback
- End-to-end inference workflow

---

# Technology Stack

## Application

- **Flutter**
- **Dart**
- Cross-platform UI
- Camera and image acquisition
- Image visualization

## AI & Data Science

- **Python**
- **PyTorch**
- **Torchvision**
- **Segmentation Models PyTorch**
- **timm**
- **nnU-Net**
- **Albumentations**
- **scikit-learn**
- **NumPy**
- **Pandas**
- **Matplotlib**
- **Jupyter Notebook**

## Development Environment

AI experiments were developed and evaluated using **Kaggle GPU Notebooks**.

---

# Reproducibility

To reproduce the AI experiments:

1. Open the corresponding Jupyter notebook.
2. Run the notebook in a GPU-enabled environment such as Kaggle.
3. Add the required datasets as notebook inputs.
4. Install the required Python dependencies.
5. Execute the notebook cells sequentially.

Dataset sources:

- [DFUC2022 Dataset](https://www.kaggle.com/datasets/pabodhamallawa/dfuc2022-train-release)
- [DFU Severity Grading Dataset](https://www.kaggle.com/datasets/khalidsiddiqui2003/dfu-dataset-annotated-into-4-classes)

---

# Project Workflow

The project is divided into two complementary components:

```text
┌──────────────────────────────────────────┐
│              MedConnect App              │
│            DFU Detect Interface          │
└────────────────────┬─────────────────────┘
                     │
                     ▼
             Image Acquisition
                     │
                     ▼
┌──────────────────────────────────────────┐
│            AI Assessment Pipeline         │
│                                          │
│  U-Net + ResNet34                        │
│  Wound Segmentation                      │
│                                          │
│  ResNet50v2 + CORN                       │
│  Severity Classification                 │
│                                          │
│  Confidence-Based Decision Support       │
└────────────────────┬─────────────────────┘
                     │
                     ▼
        Clinical Decision Support Output
```

The Flutter application provides the user-facing experience, while the AI pipeline contains the research models and inference logic.

---

# Disclaimer

This project is a **research prototype** and is not intended to replace professional medical examination, diagnosis, or treatment.

Model performance is dependent on the datasets, image acquisition conditions, preprocessing procedures, and evaluation protocols used during development. Predictions and recommendations should therefore be reviewed by a qualified healthcare professional before any clinical decision is made.

---

# Author

**Sahar Feki**  
Engineering Student — Manouba School of Engineering (MSE)  
Internship / Thesis Research — ReGIM-Lab


# License

This project is licensed under the **MIT License**. See the [`LICENSE`](LICENSE) file for details.
