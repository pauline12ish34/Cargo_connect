from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel
from google.oauth2 import service_account
from google.auth.transport.requests import Request
import requests
import json
import os

app = FastAPI()

SERVICE_ACCOUNT_FILE = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "service-account.json")
PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID", "cargo-app-9c5d5")


class NotificationRequest(BaseModel):
    token: str
    title: str
    body: str


def get_access_token():
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE,
        scopes=["https://www.googleapis.com/auth/firebase.messaging"],
    )
    credentials.refresh(Request())
    return credentials.token


@app.get("/")
def health_check():
    return {"status": "ok", "service": "cargo-app notifications", "project": PROJECT_ID}


API_KEY = os.getenv("API_KEY", "super-secret-api-key-2026")

@app.post("/send-notification")
def send_notification(req: NotificationRequest, x_api_key: str = Header(None)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")
    try:
        access_token = get_access_token()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Auth error: {str(e)}")

    url = f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json; UTF-8",
    }
    message = {
        "message": {
            "token": req.token,
            "notification": {
                "title": req.title,
                "body": req.body,
            },
        }
    }
    response = requests.post(url, headers=headers, data=json.dumps(message))
    if response.status_code != 200:
        raise HTTPException(status_code=500, detail=f"FCM error: {response.text}")
    return {"success": True, "fcm_response": response.json()}
