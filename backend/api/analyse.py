from fastapi import APIRouter, HTTPException
import cv2, numpy as np, uuid

from services import ai_pipeline
from services.storage import download_bytes, upload_bytes
from services.db import get_analysis, update_analysis

router = APIRouter()

@router.post("/analyses/{analysis_id}/process")
async def process_analysis(analysis_id: uuid.UUID):
    analysis = await get_analysis(analysis_id)
    if analysis is None:
        raise HTTPException(404, "Analysis not found")

    raw_bytes = await download_bytes(analysis.raw_image_path)
    img_bgr = cv2.imdecode(np.frombuffer(raw_bytes, np.uint8), cv2.IMREAD_COLOR)
    if img_bgr is None or img_bgr.size == 0:
        raise HTTPException(status_code=422, detail="The uploaded file is not a valid image.")
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)

    result = ai_pipeline.run_full_pipeline(img_rgb)

    encoded_mask_ok, encoded_mask = cv2.imencode(".png", result["mask_full"] * 255)
    if not encoded_mask_ok:
        raise HTTPException(status_code=500, detail="The segmentation mask could not be encoded.")
    mask_png = encoded_mask.tobytes()
    mask_path = f"masks/{analysis.patient_id}/{analysis_id}/mask.png"
    await upload_bytes(mask_path, mask_png, content_type="image/png")

    overlay = np.zeros((*result["mask_full"].shape, 4), dtype=np.uint8)
    overlay[..., 0] = 255
    overlay[..., 3] = (result["mask_full"] > 0).astype(np.uint8) * 115
    encoded_overlay_ok, encoded_overlay = cv2.imencode(".png", overlay)
    if not encoded_overlay_ok:
        raise HTTPException(status_code=500, detail="The segmentation overlay could not be encoded.")
    overlay_path = f"masks/{analysis.patient_id}/{analysis_id}/overlay.png"
    await upload_bytes(overlay_path, encoded_overlay.tobytes(), content_type="image/png")

    if result["fell_back"]:
        await update_analysis(
            analysis_id,
            status="complete",
            fell_back=True,
            mask_path=mask_path,
            overlay_path=overlay_path,
        )
        return {
            "analysis_id": str(analysis_id),
            "status": "complete",
            "fell_back": True,
            "mask_url": f"/storage/{mask_path}",
            "overlay_url": f"/storage/{overlay_path}",
            "message": "No clear wound boundary detected — try retaking the photo.",
        }

    c = result["classification"]
    await update_analysis(
        analysis_id,
        status="complete",
        fell_back=False,
        mask_path=mask_path,
        overlay_path=overlay_path,
        bbox=result["bbox"],
        grade=c["predicted_grade"],
        class_probabilities=c["class_probabilities"],
        recommendation_message=c["message"],
        classification_status=c["status"],
    )
    return {
        "analysis_id": str(analysis_id),
        "status": "complete",
        "fell_back": False,
        "mask_url": f"/storage/{mask_path}",
        "overlay_url": f"/storage/{overlay_path}",
        "bbox": result["bbox"],
        "grade": c["predicted_grade"],
        "class_probabilities": c["class_probabilities"],
        "classification_status": c["status"],
        "message": c["message"],
    }