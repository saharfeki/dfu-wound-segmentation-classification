# dfu-wound-segmentation-classification
### Wound Segmentation · Severity Classification · Decision Support

An end-to-end AI pipeline for automated diabetic foot ulcer (DFU) assessment — from raw RGB image to a clinically actionable severity grade and dressing recommendation. The system combines deep learning-based wound segmentation, ordinal severity classification, and a confidence-based decision support layer that defers uncertain cases to manual clinical review.


## Overview

Diabetic foot ulcers carry a high risk of severe infection and lower-limb amputation, and their assessment is often hampered by inconsistent monitoring, delayed detection of severity progression, and subjective clinical grading. This project builds an automated pipeline to support clinicians with objective, consistent, and reproducible DFU assessment — validated end-to-end, from smartphone/clinical image input to final recommendation.

**Pipeline stages:**
1. **Input** — RGB image of the foot ulcer (smartphone or clinical capture).
2. **Segmentation** — isolates the wound region from the surrounding tissue.
3. **Classification** — grades wound severity (Grade 1–4) using ordinal regression.
4. **Decision Support** — outputs a dressing recommendation when model confidence is high, or flags the case for manual clinical review when it is not.


##  Repository Structure

├── 01_unet_resnet34_nnunet_segmentation_classification.ipynb
├── 02_resnet50v2_corn_ordinal_full_pipeline.ipynb
└── README.md


### `01_unet_resnet34_nnunet_segmentation_classification.ipynb`
Segmentation stage of the pipeline (Phase I) and early classification experiments (Phase II baseline).
- Trains and compares **FPN + ResNeXt50** vs. **U-Net + ResNet34** for wound segmentation on the DFUC2022 benchmark.
- Evaluates an **nnU-Net** baseline as an alternative segmentation framework.
- Selects the best-performing, most efficient segmentation model based on Dice score and training cost.
- Explores a segmentation-assisted classification pipeline (4-channel RGB + mask input) with Min-Max normalization and background removal, and runs the ablation study comparing 4-channel vs. RGB-only classification input.

### `02_resnet50v2_corn_ordinal_full_pipeline.ipynb`
Final classification stage (Phase II) and full decision support integration.
- Trains the final **RGB-only severity classifier**: ResNet50v2 (BiT) backbone with a **CORN ordinal regression head**.
- Applies training strategy improvements (AdamW with discriminative learning rates, cosine annealing, data augmentation, two-phase fine-tuning, test-time augmentation).
- Applies class-weighted CORN loss and threshold calibration to correct Grade 1 / Grade 2 confusion.
- Implements the confidence-based decision support logic (dressing recommendation vs. manual review flag).
- Runs the full end-to-end pipeline: image → segmentation → crop → classification → recommendation.


## Methodology

### Phase I — Wound Segmentation
| Model | Dice Score | Training Time |
|---|---|---|
| FPN + ResNeXt50 (baseline, 3-fold CV + TTA) | 0.8175 | ~3 hours |
| **U-Net + ResNet34 (selected)** | **0.8241** | **~1 hour** |
| nnU-Net (validation) | 0.824 | — |
| nnU-Net (test) | 0.7526 | — |

**U-Net + ResNet34** was selected as the final segmentation model: it matched or exceeded baseline accuracy at a fraction of the training cost, and generalized more reliably to held-out data than nnU-Net.

### Phase II — Severity Classification
Severity grades (DFU dataset, image-only, no ground-truth masks):
- **Grade 1** — Superficial ulcer, no infection
- **Grade 2** — Deep ulcer reaching tendon or capsule
- **Grade 3** — Deep ulcer with bone involvement
- **Grade 4** — Localized gangrene

A segmentation-assisted (4-channel RGB + mask) classification approach was first explored, but an ablation study showed it performed on par with RGB-only input (56.7% accuracy in both cases), while segmentation itself proved unreliable on unseen images (missing wounds, over-segmentation, fragmented masks). **RGB-only input was therefore adopted** for the final model, using:
- **Backbone:** ResNet50v2 (BiT)
- **Head:** CORN ordinal regression (penalizes distant grade misclassifications, respecting clinical grade ordering)
- **Optimization:** AdamW with discriminative learning rates, cosine annealing, data augmentation, two-phase fine-tuning, test-time augmentation
- **Refinement:** class-weighted CORN loss and threshold calibration to improve Grade 1 recall

### Decision Support Layer
1. Predict severity grade with confidence score and prediction margin.
2. **High confidence** → automatic grade-specific dressing recommendation.
3. **Low confidence / close margin** → flagged for manual clinical review.


## Results

### Segmentation
- Final Dice score: **0.8241** (U-Net + ResNet34)

### Classification (progressive improvements)
| Stage | Accuracy | Macro F1 | MAE | QWK |
|---|---|---|---|---|
| Initial (RGB-only vs. 4-channel) | 56.7% | 54.6% / 55.1% | — | — |
| + Optimized training strategy | 61.7% | 59.3% | — | — |
| Intermediate final model | 75.3% | — | 0.291 | 0.813 |
| **Final model (after refinement)** | **80.64%** | **80.07%** | **0.209** | **0.888** |

A QWK of 0.888 indicates strong agreement with clinical grading, meaning prediction errors are rarely far from the true severity grade.

### Decision Support
- **97.6% accuracy** on high-confidence predictions, with automatic fallback to manual review for uncertain cases — validated across the complete end-to-end pipeline.



## Datasets

| Dataset | Description | Ground Truth |
|---|---|---|
| **DFUC2022** | 2,000 RGB diabetic foot ulcer images | Binary segmentation masks |
| **DFU Severity Grading Dataset** | Images labeled with severity Grade 1–4 | Class labels only (no masks) |

## Environment & Dependencies

Developed and run on **Kaggle Notebooks** (GPU runtime).

Main libraries:
- `torch`, `torchvision`
- `segmentation-models-pytorch` (smp)
- `timm`
- `coral-pytorch` / CORN ordinal regression implementation
- `nnunetv2`
- `albumentations`
- `scikit-learn`, `numpy`, `pandas`, `matplotlib`


## Usage

1. Open `01_unet_resnet34_nnunet_segmentation_classification.ipynb` on Kaggle to reproduce segmentation model training and comparison.
2. Open `02_resnet50v2_corn_ordinal_full_pipeline.ipynb` to reproduce the final classification model and run the full end-to-end decision support pipeline.
3. Attach the DFUC2022 and DFU severity grading datasets as Kaggle input datasets before running (see links above).

## Conclusion

This project delivers a validated, end-to-end AI pipeline for diabetic foot ulcer assessment. The final RGB-only ordinal classification model (ResNet50v2 + CORN) outperforms more complex multi-channel approaches, and the confidence-based decision support framework ensures clinical safety by deferring uncertain cases to manual review.

## Author

Sahar — First-year Engineering Student, MSE
Internship / Thesis work conducted at ReGIM-Lab
