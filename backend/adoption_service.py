# adoption_service.py
from fastapi import FastAPI, HTTPException
import redis
import json

app = FastAPI()
redis_client = redis.Redis(host="localhost", port=6379, decode_responses=True)


@app.post("/adopt")
def adopt(data: dict):
    email     = data.get("email")
    animal_id = data.get("animal_id")

    if not email or not animal_id:
        raise HTTPException(status_code=400, detail="email et animal_id requis")

    try:
        animal_id = int(animal_id)
    except (ValueError, TypeError):
        raise HTTPException(status_code=400, detail="animal_id doit être un entier")

    # Vérifier doublon
    existing = redis_client.lrange(f"user:{email}:adoptions", 0, -1)
    for item in existing:
        try:
            parsed = json.loads(item)
            if parsed.get("animal_id") == animal_id:
                raise HTTPException(status_code=409, detail="Vous avez déjà adopté cet animal")
        except json.JSONDecodeError:
            pass

    redis_client.lpush(
        "adoption_requests",
        json.dumps({"email": email, "animal_id": animal_id}),
    )

    return {"message": "Demande d'adoption envoyée", "animal_id": animal_id, "email": email}


@app.delete("/adopt/{animal_id}")
def cancel_adoption(animal_id: int, data: dict):
    """
    Annule l'adoption d'un animal pour un utilisateur donné.
    Body : { "email": str }
    """
    email = data.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="email requis")

    key = f"user:{email}:adoptions"
    items = redis_client.lrange(key, 0, -1)

    removed = False
    for item in items:
        try:
            parsed = json.loads(item)
            if parsed.get("animal_id") == animal_id:
                redis_client.lrem(key, 1, item)
                removed = True
                break
        except json.JSONDecodeError:
            pass

    if not removed:
        raise HTTPException(status_code=404, detail="Adoption non trouvée")

    # Notifier animal_service pour remettre le statut à "available"
    redis_client.lpush(
        "cancel_requests",
        json.dumps({"email": email, "animal_id": animal_id}),
    )

    return {"message": f"Adoption de l'animal {animal_id} annulée", "animal_id": animal_id}


@app.get("/adoptions")
def get_all_adoptions():
    keys = redis_client.keys("user:*:adoptions")
    adoptions = []
    for key in keys:
        items = redis_client.lrange(key, 0, -1)
        for item in items:
            try:
                adoptions.append(json.loads(item))
            except json.JSONDecodeError:
                pass
    return adoptions


@app.get("/adoptions/{email}")
def get_user_adoptions(email: str):
    items = redis_client.lrange(f"user:{email}:adoptions", 0, -1)
    adoptions = []
    for item in items:
        try:
            adoptions.append(json.loads(item))
        except json.JSONDecodeError:
            pass
    return adoptions


@app.get("/adoption_status/{email}")
def adoption_status(email: str):
    msg = redis_client.brpop(f"user:{email}:adoption", timeout=5)
    if not msg:
        return {"status": "pending"}
    try:
        data = json.loads(msg[1])
        return {"animal_id": data["animal_id"], "status": data["status"]}
    except (json.JSONDecodeError, KeyError) as e:
        raise HTTPException(status_code=500, detail=f"Erreur Redis : {e}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8003)