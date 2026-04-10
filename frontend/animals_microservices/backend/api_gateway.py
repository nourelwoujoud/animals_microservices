# api_gateway.py
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
import httpx

app = FastAPI()

# ── CORS (Flutter Web / Postman) ──────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── URLs des microservices ────────────────────────────────────────────────────
AUTH_URL     = "http://127.0.0.1:8001"   # ← Auth Service    (corrigé : était 8000)
ANIMAL_URL   = "http://127.0.0.1:8002"   # ← Animal Service  (corrigé : était 8001)
ADOPTION_URL = "http://127.0.0.1:8003"   # ← Adoption Service(corrigé : était 8002)

# ── Helpers ───────────────────────────────────────────────────────────────────

def _forward_headers(request: Request) -> dict:
    """Transfère le header Authorization (JWT) vers les microservices."""
    headers = {}
    auth = request.headers.get("Authorization")
    if auth:
        headers["Authorization"] = auth
    return headers


# ── Auth ──────────────────────────────────────────────────────────────────────

@app.post("/register")
async def register(user: dict):
    """
    Body attendu : { "name": str, "email": str, "password": str }
    """
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(f"{AUTH_URL}/register", json=user)
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))


@app.post("/login")                        # ← route manquante, ajoutée
async def login(credentials: dict):
    """
    Body attendu : { "email": str, "password": str }
    Retourne     : { "access_token": str, "token_type": "bearer" }
    """
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(f"{AUTH_URL}/login", json=credentials)
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))


# ── Animaux ───────────────────────────────────────────────────────────────────

@app.get("/animals")                       # ← doublon supprimé
async def get_animals(request: Request):
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(
                f"{ANIMAL_URL}/animals",
                headers=_forward_headers(request),   # ← JWT transmis
            )
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))


# ── Adoption ──────────────────────────────────────────────────────────────────

@app.post("/adopt")
async def adopt(adopt_info: dict, request: Request):
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(
                f"{ADOPTION_URL}/adopt",
                json=adopt_info,
                headers=_forward_headers(request),   # ← JWT transmis
            )
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))


@app.get("/adoptions")
async def get_adoptions(request: Request):
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(
                f"{ADOPTION_URL}/adoptions",
                headers=_forward_headers(request),   # ← JWT transmis
            )
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))
