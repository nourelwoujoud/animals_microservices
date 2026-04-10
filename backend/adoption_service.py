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

    # FIX : vérifier que animal_id est bien un entier
    try:
        animal_id = int(animal_id)
    except (ValueError, TypeError):
        raise HTTPException(status_code=400, detail="animal_id doit être un entier")

    # Envoyer la demande à animal_service via Redis
    redis_client.lpush(
        "adoption_requests",
        json.dumps({"email": email, "animal_id": animal_id}),
    )

    return {"message": "Demande d'adoption envoyée", "animal_id": animal_id, "email": email}


@app.get("/adoptions")                                      # FIX : route renommée "/adoptions" (cohérence avec Gateway)
def get_adoptions():
    """Retourne toutes les clés d'adoption stockées dans Redis."""
    keys = redis_client.keys("user:*:adoption")
    adoptions = []
    for key in keys:
        items = redis_client.lrange(key, 0, -1)
        for item in items:
            try:
                adoptions.append(json.loads(item))
            except json.JSONDecodeError:
                pass
    return adoptions


@app.get("/adoption_status/{email}")
def adoption_status(email: str):
    """Vérifie le statut d'adoption pour un email donné (polling)."""
    msg = redis_client.brpop(f"user:{email}:adoption", timeout=5)

    if not msg:
        return {"status": "pending"}

    try:
        data = json.loads(msg[1])
        return {"animal_id": data["animal_id"], "status": data["status"]}
    except (json.JSONDecodeError, KeyError) as e:           # FIX : gérer les erreurs de parsing
        raise HTTPException(status_code=500, detail=f"Erreur de lecture Redis : {e}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8003)            # FIX : port 8003 cohérent avec la Gateway