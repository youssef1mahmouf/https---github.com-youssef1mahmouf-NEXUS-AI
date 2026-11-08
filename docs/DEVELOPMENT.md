# Nexus AI — Development

## Environment

- Flutter SDK (Dart ^3.11.5)
- Python 3.11+
- Ollama (optional, for local models)

## Backend

cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --port 8001

## Frontend

cd frontend
flutter pub get
flutter run

## Tests

Backend: pytest
Frontend: flutter test

## Git

Remote: <https://github.com/youssef1mahmouf/NEXUS-AI.git>
Branch: main
