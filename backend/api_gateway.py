# api_gateway.py
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
import httpx
import json
from jose import jwt, JWTError

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

AUTH_URL     = "http://127.0.0.1:8001"
ANIMAL_URL   = "http://127.0.0.1:8002"
ADOPTION_URL = "http://127.0.0.1:8003"

SECRET_KEY = "SECRET123"
ALGORITHM  = "HS256"


def _forward_headers(request: Request) -> dict:
    auth = request.headers.get("Authorization")
    return {"Authorization": auth} if auth else {}


def _extract_email(request: Request) -> str | None:
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return None
    token = auth.split(" ", 1)[1]
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")
    except JWTError as e:
        print(f"❌ JWT invalide : {e}")
        return None


# ── Auth ──────────────────────────────────────────────────────────────────────

@app.post("/register")
async def register(user: dict):
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(f"{AUTH_URL}/register", json=user)
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))


@app.post("/login")
async def login(credentials: dict):
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(f"{AUTH_URL}/login", json=credentials)
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))


# ── Animals ───────────────────────────────────────────────────────────────────

@app.get("/animals")
async def get_animals(request: Request):
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(f"{ANIMAL_URL}/animals", headers=_forward_headers(request))
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))


# ── Adoption ──────────────────────────────────────────────────────────────────

@app.post("/adopt")
async def adopt(adopt_info: dict, request: Request):
    email = _extract_email(request)
    if not email:
        raise HTTPException(status_code=401, detail="Token invalide ou expiré")

    payload = {**adopt_info, "email": email}

    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(
                f"{ADOPTION_URL}/adopt",
                json=payload,
                headers=_forward_headers(request),
            )
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))


@app.delete("/adopt/{animal_id}")
async def cancel_adoption(animal_id: int, request: Request):
    """
    FIX : httpx.delete() ne supporte pas json= directement.
    On passe le body via content= + headers Content-Type manuellement.
    """
    email = _extract_email(request)
    if not email:
        raise HTTPException(status_code=401, detail="Token invalide ou expiré")

    body    = json.dumps({"email": email})
    headers = {**_forward_headers(request), "Content-Type": "application/json"}

    async with httpx.AsyncClient() as client:
        try:
            resp = await client.request(
                "DELETE",
                f"{ADOPTION_URL}/adopt/{animal_id}",
                content=body,          # ✅ FIX : request() supporte content= sur DELETE
                headers=headers,
            )
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))


@app.get("/my_adoptions")
async def get_my_adoptions(request: Request):
    email = _extract_email(request)
    if not email:
        raise HTTPException(status_code=401, detail="Token invalide ou expiré")

    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(
                f"{ADOPTION_URL}/adoptions/{email}",
                headers=_forward_headers(request),
            )
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))


@app.get("/adoptions")
async def get_all_adoptions(request: Request):
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(f"{ADOPTION_URL}/adoptions", headers=_forward_headers(request))
            resp.raise_for_status()
            return resp.json()
        except httpx.HTTPStatusError as e:
            raise HTTPException(status_code=e.response.status_code, detail=e.response.text)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))