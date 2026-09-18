from pathlib import Path

STORAGE_ROOT = Path(__file__).parent.parent / "storage"
STORAGE_ROOT.mkdir(exist_ok=True)

async def upload_bytes(key: str, data: bytes, content_type: str = "application/octet-stream"):
    path = STORAGE_ROOT / key
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return key

async def download_bytes(key: str) -> bytes:
    return (STORAGE_ROOT / key).read_bytes()