# animal_service.py
from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData, select, update
import redis
import json
import threading

# ── PostgreSQL ────────────────────────────────────────────────────────────────
engine = create_engine("postgresql://postgres:0000@localhost:5432/animal_adoption_db")
metadata = MetaData()

animals = Table(
    "animals", metadata,
    Column("id",          Integer, primary_key=True),
    Column("name",        String),
    Column("type",        String),
    Column("breed",       String),
    Column("age",         Integer),
    Column("gender",      String),
    Column("description", String),
    Column("status",      String, default="available"),
)

metadata.create_all(engine)

# ── Redis ─────────────────────────────────────────────────────────────────────
redis_client = redis.Redis(host="localhost", port=6379, decode_responses=True)

# ── App ───────────────────────────────────────────────────────────────────────
app = FastAPI()

# ── Helpers ───────────────────────────────────────────────────────────────────

def get_connection():
    """Retourne une connexion SQLAlchemy."""
    return engine.connect()

# ── Endpoints ─────────────────────────────────────────────────────────────────

@app.get("/animals")
def get_animals():
    with get_connection() as conn:                          # FIX : utiliser "with" (fermeture auto)
        result = conn.execute(select(animals)).fetchall()
    return [dict(row._mapping) for row in result]


@app.get("/animals/{animal_id}")
def get_animal(animal_id: int):
    with get_connection() as conn:
        result = conn.execute(
            select(animals).where(animals.c.id == animal_id)
        ).first()

    if not result:
        raise HTTPException(status_code=404, detail="Animal non trouvé")

    return dict(result._mapping)


@app.post("/update_status")
def update_status(data: dict):
    animal_id = data.get("animal_id")
    status    = data.get("status")

    if not animal_id or not status:
        raise HTTPException(status_code=400, detail="animal_id et status requis")

    # Vérifier que l'animal existe avant de mettre à jour
    with get_connection() as conn:
        existing = conn.execute(
            select(animals).where(animals.c.id == animal_id)
        ).first()

        if not existing:                                    # FIX : vérification existence ajoutée
            raise HTTPException(status_code=404, detail="Animal non trouvé")

        conn.execute(
            update(animals).where(animals.c.id == animal_id).values(status=status)
        )
        conn.commit()                                       # FIX : commit dans le même "with"

    return {"message": f"Animal {animal_id} mis à jour → {status}"}


# ── Redis Listener ────────────────────────────────────────────────────────────

def listen_adoptions():
    """Écoute la queue Redis et met à jour le statut des animaux adoptés."""
    print("🔴 Redis listener démarré...")
    while True:
        try:
            msg = redis_client.blpop("adoption_requests", timeout=0)
            if not msg:
                continue

            data      = json.loads(msg[1])
            animal_id = data.get("animal_id")
            email     = data.get("email")

            if not animal_id or not email:
                print("⚠️  Message Redis invalide :", data)
                continue

            # Mettre le statut à "adopted"
            with get_connection() as conn:
                conn.execute(
                    update(animals)
                    .where(animals.c.id == animal_id)
                    .values(status="adopted")
                )
                conn.commit()

            print(f"✅ Animal {animal_id} adopté par {email}")

            # Confirmer à l'adoption_service via Redis
            redis_client.lpush(
                f"user:{email}:adoption",
                json.dumps({"animal_id": animal_id, "status": "adopted"}),
            )

        except Exception as e:                              # FIX : ne pas crasher le thread sur erreur
            print("❌ Erreur Redis listener :", e)


@app.on_event("startup")
def start_redis_listener():
    thread = threading.Thread(target=listen_adoptions, daemon=True)
    thread.start()
    print("🚀 Animal Service démarré sur le port 8002")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)            