_analyses: dict[str, dict] = {}

async def create_analysis_row(id, patient_id, created_by, source, raw_image_path, status="pending"):
    _analyses[str(id)] = {"id": str(id), "patient_id": str(patient_id), "created_by": str(created_by),
                           "source": source, "raw_image_path": raw_image_path, "status": status}

async def get_analysis(analysis_id):
    row = _analyses.get(str(analysis_id))
    return type("Analysis", (), row) if row else None

async def update_analysis(analysis_id, **fields):
    _analyses[str(analysis_id)].update(fields)