import os
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from dotenv import load_dotenv
import requests


GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.1-8b-instant"

_THIS_DIR = Path(__file__).resolve().parent
load_dotenv(_THIS_DIR / ".env")
load_dotenv(_THIS_DIR.parent / ".env")
load_dotenv(_THIS_DIR.parent.parent / ".env")

app = FastAPI(title="AI Hint Reguests API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST", "OPTIONS"],
    allow_headers=["*"],
)


class AIHintReguestsIn(BaseModel):
    task_type: str = Field(..., min_length=1, description="Тип задания")
    player_code: str = Field(..., min_length=1, description="Код игрока")
    task_prompt: str = Field(..., min_length=1, description="Промпт задания")


def _build_user_prompt(task_type: str, task_prompt: str, player_code: str) -> str:
    return (
        "Ты помощник по обучению программированию. "
        "Дай краткую и полезную подсказку на русском, без полного готового решения.\n\n"
        f"Тип задания: {task_type}\n"
        f"Условие/промпт задания:\n{task_prompt}\n\n"
        "Код игрока:\n"
        "```python\n"
        f"{player_code}\n"
        "```"
    )


@app.post("/ai_hint_reguests")
def ai_hint_reguests(data: AIHintReguestsIn):
    api_key = os.getenv("GROQ_API_KEY", "").strip()
    if not api_key:
        return {
            "ok": False,
            "error": "GROQ_API_KEY не настроен на сервере.",
        }

    user_prompt = _build_user_prompt(data.task_type, data.task_prompt, data.player_code)
    payload = {
        "model": GROQ_MODEL,
        "messages": [{"role": "user", "content": user_prompt}],
        "temperature": 0.6,
        "max_tokens": 768,
    }
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": f"Bearer {api_key}",
        "User-Agent": "schoolgame-ai-hint/1.0",
    }

    try:
        resp = requests.post(GROQ_API_URL, json=payload, headers=headers, timeout=30)
        parsed = resp.json() if resp.text else {}
    except requests.RequestException as e:
        return {"ok": False, "error": f"Ошибка сети при вызове Groq: {e}"}
    except Exception as e:
        return {"ok": False, "error": f"Ошибка сети при вызове Groq: {e}"}

    if resp.status_code != 200:
        err_message = ""
        if isinstance(parsed, dict):
            err_obj = parsed.get("error", {})
            if isinstance(err_obj, dict):
                err_message = str(err_obj.get("message", "")).strip()
        if err_message == "":
            err_message = resp.text.strip()[:500]
        return {"ok": False, "error": f"Groq HTTP {resp.status_code}: {err_message}"}

    choices = parsed.get("choices", [])
    if not choices:
        return {"ok": False, "error": "Groq вернул пустой список choices."}

    message = choices[0].get("message", {})
    hint = str(message.get("content", "")).strip()
    if not hint:
        return {"ok": False, "error": "Groq вернул пустую подсказку."}

    return {
        "ok": True,
        "task_type": data.task_type,
        "hint": hint,
    }
