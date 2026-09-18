from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from api import analyse, analyses
from services import ai_pipeline

@asynccontextmanager
async def lifespan(app: FastAPI):
    ai_pipeline.load_all_models()
    yield

app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount(
    "/storage",
    StaticFiles(directory=Path(__file__).parent.parent / "storage"),
    name="storage",
)

@app.get("/")
async def health_check():
    return {"status": "ok", "service": "dfu-wound-api"}

app.include_router(analyses.router)
app.include_router(analyse.router)