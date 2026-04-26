PRÉREQUIS :
- Docker Desktop installé et lancé
- PostgreSQL 15 installé (port 5432, mot de passe: 0000)
- Flutter SDK installé (pour le frontend)

ÉTAPES :

1. Créer la base de données PostgreSQL :
   - Ouvrir pgAdmin ou psql
   - Créer une base nommée : animal_adoption_db

2. Lancer le backend (dans le dossier animal_adoption_app) :
   docker-compose up --build

3. Lancer le frontend (dans un autre terminal) :
   cd frontend
   flutter run -d chrome --web-renderer html

L'application est accessible sur : http://localhost:8000