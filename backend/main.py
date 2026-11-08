import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("nexus-ai-backend")

import json
import os
import uuid
from typing import List, Optional

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from config import API_HOST, API_PORT, DEFAULT_MODEL, UPLOAD_DIR
import ai

app = FastAPI(title="Nexus AI Backend", version="1.0.0")

_cors_origins = [o.strip() for o in os.getenv("CORS_ORIGINS", "*").split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

os.makedirs(UPLOAD_DIR, exist_ok=True)


class HistoryMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    message: str
    conversation_id: Optional[str] = None
    history: List[HistoryMessage] = []
    model: Optional[str] = None


class ChatResponse(BaseModel):
    reply: str
    conversation_id: str
    model: str


class UploadResponse(BaseModel):
    id: str
    filename: str
    size: int


@app.get("/health")
def health():
    return {"status": "ok", "service": "nexus-ai-backend", "model": DEFAULT_MODEL}


@app.get("/models")
def models():
    try:
        return {"models": ai.list_models()}
    except Exception as exc:  # noqa: BLE001
        logger.exception("Failed to list models")
        raise HTTPException(status_code=502, detail=f"Ollama error: {exc}")


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="Message is empty")
    messages = [{"role": m.role, "content": m.content} for m in req.history]
    messages.append({"role": "user", "content": req.message})
    logger.info("chat request conversation=%s model=%s", req.conversation_id, req.model)
    try:
        reply, model = ai.chat(messages, model=req.model)
    except Exception as exc:  # noqa: BLE001
        logger.exception("AI provider failure")
        raise HTTPException(status_code=502, detail=f"AI provider error: {exc}")
    conversation_id = req.conversation_id or str(uuid.uuid4())
    return ChatResponse(reply=reply, conversation_id=conversation_id, model=model)


@app.post("/upload", response_model=UploadResponse)
async def upload(file: UploadFile = File(...)):
    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="Empty file")
    attachment_id = str(uuid.uuid4())
    safe_name = file.filename or "upload.bin"
    path = os.path.join(UPLOAD_DIR, f"{attachment_id}_{safe_name}")
    with open(path, "wb") as f:
        f.write(data)
    return UploadResponse(id=attachment_id, filename=safe_name, size=len(data))


@app.post("/chat/stream")
async def chat_stream(req: ChatRequest):
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="Message is empty")
    messages = [{"role": m.role, "content": m.content} for m in req.history]
    messages.append({"role": "user", "content": req.message})
    conversation_id = req.conversation_id or str(uuid.uuid4())
    model = req.model or DEFAULT_MODEL
    logger.info("chat stream request conversation=%s model=%s", conversation_id, model)

    async def event_generator():
        try:
            for chunk in ai.chat_stream(messages, model=model):
                yield f"data: {json.dumps({'reply': chunk, 'conversation_id': conversation_id, 'model': model})}\n\n"
            yield "data: [DONE]\n\n"
        except Exception as exc:  # noqa: BLE001
            logger.exception("AI stream failure")
            yield f"data: {json.dumps({'error': str(exc)})}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")

