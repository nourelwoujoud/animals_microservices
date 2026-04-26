# animal_service.py
from fastapi import FastAPI, HTTPException
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData, select, update
import redis
import json
import threading
import os

# ✅ FIX : host.docker.internal pour atteindre PostgreSQL depuis Docker
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:0000@host.docker.internal:5432/animal_adoption_db"
)

engine = create_engine(DATABASE_URL)
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

# ✅ FIX : REDIS_HOST depuis env Docker
redis_client = redis.Redis(
    host=os.getenv("REDIS_HOST", "localhost"),
    port=int(os.getenv("REDIS_PORT", "6379")),
    decode_responses=True
)

app = FastAPI()


def get_connection():
    return engine.connect()


@app.get("/animals")
def get_animals():
    with get_connection() as conn:
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
    with get_connection() as conn:
        existing = conn.execute(select(animals).where(animals.c.id == animal_id)).first()
        if not existing:
            raise HTTPException(status_code=404, detail="Animal non trouvé")
        conn.execute(update(animals).where(animals.c.id == animal_id).values(status=status))
        conn.commit()
    return {"message": f"Animal {animal_id} → {status}"}


def listen_redis():
    print("🔴 Redis listener démarré...")
    while True:
        try:
            msg = redis_client.blpop(["adoption_requests", "cancel_requests"], timeout=0)
            if not msg:
                continue

            queue = msg[0]
            data  = json.loads(msg[1])
            animal_id = data.get("animal_id")
            email     = data.get("email")

            if not animal_id or not email:
                print("⚠️  Message invalide :", data)
                continue

            if queue == "adoption_requests":
                animal_data = None
                with get_connection() as conn:
                    row = conn.execute(
                        select(animals).where(animals.c.id == animal_id)
                    ).first()
                    if row:
                        animal_data = dict(row._mapping)
                    conn.execute(
                        update(animals).where(animals.c.id == animal_id).values(status="adopted")
                    )
                    conn.commit()

                print(f"✅ Animal {animal_id} adopté par {email}")

                adoption_record = {
                    "animal_id": animal_id,
                    "status": "adopted",
                    "email": email,
                    "animal": animal_data or {"id": animal_id},
                }
                redis_client.lpush(f"user:{email}:adoptions", json.dumps(adoption_record))
                redis_client.lpush(f"user:{email}:adoption",  json.dumps({"animal_id": animal_id, "status": "adopted"}))

            elif queue == "cancel_requests":
                with get_connection() as conn:
                    conn.execute(
                        update(animals).where(animals.c.id == animal_id).values(status="available")
                    )
                    conn.commit()
                print(f"🔄 Animal {animal_id} remis disponible (annulation par {email})")

        except Exception as e:
            print("❌ Erreur Redis listener :", e)


@app.on_event("startup")
def start_redis_listener():
    thread = threading.Thread(target=listen_redis, daemon=True)
    thread.start()
    print("🚀 Animal Service démarré sur le port 8002")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)