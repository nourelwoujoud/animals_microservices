# auth_service.py
from fastapi import FastAPI, HTTPException
from passlib.context import CryptContext
from jose import jwt
import datetime
from pymongo import MongoClient

# ── MongoDB 
MONGO_URL = "mongodb+srv://mongo:1234@cluster0.huvqsic.mongodb.net/animal_db?retryWrites=true&w=majority"
client = MongoClient(MONGO_URL)
db = client["animal_db"]
users_collection = db["users"]

# ── App 
app = FastAPI()

# ── JWT & Hash
SECRET_KEY = "SECRET123"
ALGORITHM  = "HS256"
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ── Helpers ───────────────────────────────────────────────────────────────────

def hash_password(password: str) -> str:
    return pwd_context.hash(password[:72].encode("utf-8"))

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain[:72].encode("utf-8"), hashed)

def create_token(email: str) -> str:
    payload = {
        "sub": email,                                           # FIX : "sub" est la convention JWT standard (était "email")
        "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=2),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.post("/register")
def register(user: dict):
    print("Incoming register:", user)

    # Validation des champs
    for field in ["name", "email", "password"]:
        if field not in user or not str(user[field]).strip():
            raise HTTPException(status_code=400, detail=f"Champ manquant ou vide : {field}")

    # Email déjà utilisé
    if users_collection.find_one({"email": user["email"]}):
        raise HTTPException(status_code=400, detail="Email déjà utilisé")

    # Longueur minimale du mot de passe
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
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")  # FIX : message neutre (sécurité)

    if not verify_password(user["password"], db_user["password"]):
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")  # FIX : même message (sécurité)

    token = create_token(user["email"])

    return {
        "access_token": token,          # FIX : renommé "token" → "access_token" (convention OAuth2 / Flutter attend ça)
        "token_type":   "bearer",       # FIX : ajouté (standard OAuth2)
        "email":        user["email"],
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)   
