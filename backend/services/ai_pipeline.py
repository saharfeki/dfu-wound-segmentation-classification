import torch, torch.nn as nn, cv2, numpy as np, timm
import segmentation_models_pytorch as smp
from pathlib import Path

MODEL_DIR = Path(__file__).parent.parent / "models"
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

IMAGENET_MEAN = np.array([0.485, 0.456, 0.406], dtype=np.float32)
IMAGENET_STD = np.array([0.229, 0.224, 0.225], dtype=np.float32)

PAD_RATIO = 0.35
MIN_PAD_PX = 40
MIN_CROP_SIZE = 200
MIN_BBOX_SIZE = 5

# ---------- Stage C decision config ----------
NUM_CLASSES = 4
FINAL_THRESHOLDS = [0.53, 0.90, 0.90]
CONFIDENCE_THRESHOLD = 0.50
MARGIN_THRESHOLD = 0.15
IMG_SIZE = 224

GRADE_TO_STAGE = {
    0: "Infection",     # Grade 1 — see clinical-validity flag from source notebook
    1: "Granulation",   # Grade 2
    2: "Fibrin",        # Grade 3
    3: "Necrosis",       # Grade 4
}
DRESSING_TABLE = {
    "Necrosis": "Hydrogel",
    "Fibrin": "Hydrocellular / Alginate",
    "Granulation": "Hydrocolloid",
    "Infection": "Silver-based / Charcoal dressing",
}

# ---------- checkpoint loading ----------
def load_checkpoint(model, path, device):
    ckpt = torch.load(path, map_location=device, weights_only=False)
    if isinstance(ckpt, dict) and "model_state_dict" in ckpt:
        state_dict = ckpt["model_state_dict"]
    elif isinstance(ckpt, dict) and "state_dict" in ckpt:
        state_dict = ckpt["state_dict"]
    else:
        state_dict = ckpt
    state_dict = {k.replace("module.", ""): v for k, v in state_dict.items()}
    model.load_state_dict(state_dict, strict=True)
    model.to(device)
    model.eval()
    return model

# ---------- Stage A: background/mask model ----------
def build_bg_model():
    return smp.Unet(encoder_name="resnet34", encoder_weights=None,
                     in_channels=3, classes=1, activation=None)

# ---------- Stage B: 4-channel refinement model ----------
def build_unet_4ch(encoder="resnet34"):
    model = smp.Unet(encoder_name=encoder, encoder_weights=None,
                      in_channels=3, classes=1, activation=None)
    old_conv = model.encoder.conv1
    new_conv = nn.Conv2d(
        4, old_conv.out_channels, old_conv.kernel_size, old_conv.stride,
        old_conv.padding, bias=old_conv.bias is not None,
    )
    with torch.no_grad():
        new_conv.weight[:, :3] = old_conv.weight
        new_conv.weight[:, 3:4] = old_conv.weight.mean(dim=1, keepdim=True)
        if old_conv.bias is not None:
            new_conv.bias[:] = old_conv.bias
    model.encoder.conv1 = new_conv
    return model

# ---------- Stage C: classifier ----------
class WoundGradingModel(nn.Module):
    def __init__(self, backbone_name="resnetv2_50x1_bit.goog_in21k", num_corn_logits=3):
        super().__init__()
        self.backbone = timm.create_model(backbone_name, pretrained=False, num_classes=0)
        feat_dim = self.backbone.num_features
        self.head = nn.Sequential(
            nn.Linear(feat_dim, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(inplace=True),
            nn.Dropout(0.4),
            nn.Linear(512, num_corn_logits),
        )

    def forward(self, x):
        return self.head(self.backbone(x))

# ---------- globals, populated once at startup ----------
model_bg = None
unet_model = None
classifier_model = None

def load_all_models():
    global model_bg, unet_model, classifier_model
    model_bg = load_checkpoint(build_bg_model(), MODEL_DIR / "best_model_bg_remove.pth", DEVICE)
    unet_model = load_checkpoint(build_unet_4ch(), MODEL_DIR / "unet_improved.pth", DEVICE)
    classifier_model = load_checkpoint(WoundGradingModel(), MODEL_DIR / "best_model_classification.pth", DEVICE)
    print("All models loaded.")

# ---------- Stage A inference ----------
def predict_bg_mask(img_rgb, threshold=0.5, size=256):
    img_resized = cv2.resize(img_rgb, (size, size)).astype(np.float32) / 255.0
    img_norm = (img_resized - IMAGENET_MEAN) / IMAGENET_STD
    tensor = torch.from_numpy(img_norm.transpose(2, 0, 1)).unsqueeze(0).float().to(DEVICE)
    with torch.no_grad():
        pred = torch.sigmoid(model_bg(tensor))
    mask = pred.squeeze().cpu().numpy()
    mask_bin = (mask > threshold).astype(np.uint8)
    return cv2.resize(mask_bin, (size, size), interpolation=cv2.INTER_NEAREST)

# ---------- Stage A + B + crop ----------
def predict_mask_and_crop(img_rgb, unet_size=256, pad_ratio=PAD_RATIO, threshold=0.5,
                           min_bbox_size=MIN_BBOX_SIZE, min_pad_px=MIN_PAD_PX,
                           min_crop_size=MIN_CROP_SIZE):
    h, w = img_rgb.shape[:2]

    bg_mask = predict_bg_mask(img_rgb, threshold=threshold, size=unet_size)
    mask_ch = bg_mask.astype(np.float32)

    img_resized = cv2.resize(img_rgb, (unet_size, unet_size)).astype(np.float32) / 255.0
    img_norm = (img_resized - IMAGENET_MEAN) / IMAGENET_STD
    four_ch = np.dstack([img_norm, mask_ch])
    tensor = torch.from_numpy(four_ch.transpose(2, 0, 1)).unsqueeze(0).float().to(DEVICE)

    with torch.no_grad():
        pred = torch.sigmoid(unet_model(tensor))
    mask = pred.squeeze().cpu().numpy()
    mask_bin = (mask > threshold).astype(np.uint8)
    mask_full = cv2.resize(mask_bin, (w, h), interpolation=cv2.INTER_NEAREST)

    ys, xs = np.where(mask_full > 0)
    if len(xs) == 0 or len(ys) == 0:
        return {"fell_back": True, "mask_full": mask_full, "bbox": None, "crop_img": None}

    x1, x2 = xs.min(), xs.max()
    y1, y2 = ys.min(), ys.max()
    bw, bh = x2 - x1, y2 - y1
    if bw < min_bbox_size or bh < min_bbox_size:
        return {"fell_back": True, "mask_full": mask_full, "bbox": None, "crop_img": None}

    pad_x = max(int(bw * pad_ratio), min_pad_px)
    pad_y = max(int(bh * pad_ratio), min_pad_px)
    x1, y1 = max(0, x1 - pad_x), max(0, y1 - pad_y)
    x2, y2 = min(w, x2 + pad_x), min(h, y2 + pad_y)

    cw, ch = x2 - x1, y2 - y1
    if cw < min_crop_size:
        extra = (min_crop_size - cw) // 2
        x1, x2 = max(0, x1 - extra), min(w, x2 + extra)
    if ch < min_crop_size:
        extra = (min_crop_size - ch) // 2
        y1, y2 = max(0, y1 - extra), min(h, y2 + extra)

    crop_img = img_rgb[y1:y2, x1:x2]
    return {"fell_back": False, "mask_full": mask_full, "bbox": (int(x1), int(y1), int(x2), int(y2)), "crop_img": crop_img}

# ---------- Stage C inference ----------
def _preprocess_for_classifier(crop_img_rgb):
    img_resized = cv2.resize(crop_img_rgb, (IMG_SIZE, IMG_SIZE)).astype(np.float32) / 255.0
    img_norm = (img_resized - IMAGENET_MEAN) / IMAGENET_STD
    return torch.from_numpy(img_norm.transpose(2, 0, 1)).unsqueeze(0).float().to(DEVICE)

def compute_confidence(probas_cumulative, thresholds=FINAL_THRESHOLDS):
    p = np.zeros(NUM_CLASSES)
    p[0] = 1 - probas_cumulative[0]
    p[1] = probas_cumulative[0] - probas_cumulative[1]
    p[2] = probas_cumulative[1] - probas_cumulative[2]
    p[3] = probas_cumulative[2]
    p = np.clip(p, 0, 1)
    p = p / p.sum()

    pred = sum(probas_cumulative[i] > t for i, t in enumerate(thresholds))
    confidence = p[pred]
    margin = np.sort(p)[-1] - np.sort(p)[-2]
    return pred, p, confidence, margin

def predict_and_recommend(crop_img_rgb):
    tensor = _preprocess_for_classifier(crop_img_rgb)
    with torch.no_grad():
        logits = classifier_model(tensor)
        probas_cumulative = torch.sigmoid(logits).cpu().numpy()[0]

    pred, p, confidence, margin = compute_confidence(probas_cumulative)

    result = {
        "predicted_grade": int(pred) + 1,
        "class_probabilities": {f"Grade {i+1}": float(p[i]) for i in range(NUM_CLASSES)},
        "confidence": float(confidence),
        "margin": float(margin),
    }

    if confidence < CONFIDENCE_THRESHOLD or margin < MARGIN_THRESHOLD:
        result.update({
            "status": "UNCERTAIN",
            "recommendation": None,
            "message": (
                f"Low-confidence prediction (confidence={confidence:.1%}, margin={margin:.1%}). "
                f"Flagged for manual clinical review rather than an automated dressing recommendation."
            ),
        })
    else:
        stage = GRADE_TO_STAGE[pred]
        dressing = DRESSING_TABLE[stage]
        result.update({
            "status": "CONFIDENT",
            "stage": stage,
            "recommendation": dressing,
            "message": f"Predicted Grade {pred+1} ({stage}) → Recommended dressing: {dressing}",
        })
    return result

# ---------- full cascade ----------
def run_full_pipeline(img_rgb):
    seg_result = predict_mask_and_crop(img_rgb)
    if seg_result["fell_back"]:
        return {
            "fell_back": True,
            "mask_full": seg_result["mask_full"],
            "bbox": None,
            "classification": None,
        }
    classification = predict_and_recommend(seg_result["crop_img"])
    return {
        "fell_back": False,
        "mask_full": seg_result["mask_full"],
        "bbox": seg_result["bbox"],
        "classification": classification,
    }