import uuid

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from services.db import create_analysis_row
from services.storage import upload_bytes

router = APIRouter()


@router.post("/analyses")
async def create_analysis(
    patient_id: str = Form(...),
    source: str = Form(...),
    image: UploadFile = File(...),
):
    if source not in {"camera", "upload"}:
        raise HTTPException(status_code=422, detail="Source must be camera or upload.")

    contents = await image.read()
    if not contents:
        raise HTTPException(status_code=422, detail="The uploaded image is empty.")
    if image.content_type not in {"image/jpeg", "image/png"}:
        raise HTTPException(status_code=422, detail="Only JPEG and PNG images are supported.")

    analysis_id = uuid.uuid4()
    ext = "jpg" if image.content_type == "image/jpeg" else "png"
    key = f"raw/{patient_id}/{analysis_id}/original.{ext}"

    await upload_bytes(key, contents, content_type=image.content_type)
    await create_analysis_row(analysis_id, patient_id, "demo-clinician", source, key)

    return {"analysis_id": str(analysis_id), "status": "pending"}
