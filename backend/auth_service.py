from fastapi import FastAPI, HTTPException
import bcrypt
from jose import jwt
import datetime
from pymongo import MongoClient

# ── MongoDB ───────────────────────────────────────────────────────────────────
MONGO_URL = "mongodb+srv://mongo:1234@cluster0.huvqsic.mongodb.net/animal_db?retryWrites=true&w=majority"
client = MongoClient(MONGO_URL)
db = client["animal_db"]
users_collection = db["users"]

# ── App ───────────────────────────────────────────────────────────────────────
app = FastAPI()

# ── JWT & Hash ────────────────────────────────────────────────────────────────
SECRET_KEY = "SECRET123"
ALGORITHM  = "HS256"


# ── Helpers ───────────────────────────────────────────────────────────────────

def hash_password(password: str) -> str:
    # ✅ FIX : encoder en bytes AVANT de truncate à 72 bytes
    password_bytes = password.encode("utf-8")[:72]
    return bcrypt.hashpw(password_bytes, bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    # ✅ FIX : encoder en bytes AVANT de truncate à 72 bytes
    plain_bytes  = plain.encode("utf-8")[:72]
    hashed_bytes = hashed.encode("utf-8")
    return bcrypt.checkpw(plain_bytes, hashed_bytes)


def create_token(email: str) -> str:
    payload = {
        "sub": email,
        "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=24),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.post("/register")
def register(user: dict):
    print("Incoming register:", user)

    for field in ["name", "email", "password"]:
        if field not in user or not str(user[field]).strip():
            raise HTTPException(status_code=400, detail=f"Champ manquant ou vide : {field}")

    if users_collection.find_one({"email": user["email"]}):
        raise HTTPException(status_code=400, detail="Email déjà utilisé")

    if len(user["password"]) < 6:
        raise HTTPException(status_code=400, detail="Le mot de passe doit contenir au moins 6 caractères")

    try:
        users_collection.insert_one({
            "name":     user["name"],
            "email":    user["email"],
            "password": hash_password(user["password"]),
        })
    except Exception as e:
        print("MongoDB insert error:", e)
        raise HTTPException(status_code=500, detail="Erreur interne du serveur")

    return {"message": "Utilisateur créé avec succès"}


@app.post("/login")
def login(user: dict):
    print("Login attempt:", user)

    if not user.get("email") or not user.get("password"):
        raise HTTPException(status_code=400, detail="Email et mot de passe requis")

    db_user = users_collection.find_one({"email": user["email"]})

    if not db_user:
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")

    if not verify_password(user["password"], db_user["password"]):
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")

    token = create_token(user["email"])

    return {
        "access_token": token,
        "token_type":   "bearer",
        "email":        user["email"],
    }


if _name_ == "_main_":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
