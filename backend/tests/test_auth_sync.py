from __future__ import annotations

import os

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import src.database.session as db_session
from src.database.base import Base
from src.database.session import get_db
from src.main import create_app


@pytest.fixture()
def client() -> TestClient:
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)

    db_session.engine = engine
    db_session.SessionLocal = TestingSessionLocal

    app = create_app()

    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    os.environ["JWT_SECRET"] = "test-secret"
    return TestClient(app)


def test_register_and_login(client: TestClient) -> None:
    register_resp = client.post(
        "/api/v1/auth/register",
        json={
            "email": "student@qurany.app",
            "password": "secret12",
            "full_name": "Student",
        },
    )
    assert register_resp.status_code == 201
    token = register_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    me_resp = client.get("/api/v1/auth/me", headers=headers)
    assert me_resp.status_code == 200
    assert me_resp.json()["email"] == "student@qurany.app"

    login_resp = client.post(
        "/api/v1/auth/login",
        data={"username": "student@qurany.app", "password": "secret12"},
    )
    assert login_resp.status_code == 200
    assert login_resp.json()["access_token"]


def test_register_rejects_duplicate_email(client: TestClient) -> None:
    payload = {
        "email": "dup@qurany.app",
        "password": "secret12",
        "full_name": "Dup",
    }
    assert client.post("/api/v1/auth/register", json=payload).status_code == 201
    assert client.post("/api/v1/auth/register", json=payload).status_code == 400


def test_login_rejects_wrong_password(client: TestClient) -> None:
    client.post(
        "/api/v1/auth/register",
        json={
            "email": "wrongpass@qurany.app",
            "password": "secret12",
            "full_name": "User",
        },
    )
    login_resp = client.post(
        "/api/v1/auth/login",
        data={"username": "wrongpass@qurany.app", "password": "badpass"},
    )
    assert login_resp.status_code == 401


def test_sync_routes_removed(client: TestClient) -> None:
    assert client.post("/api/v1/sync/push", json={}).status_code == 404
    assert client.get("/api/v1/sync/pull").status_code == 404


def test_register_rejects_invalid_email(client: TestClient) -> None:
    resp = client.post(
        "/api/v1/auth/register",
        json={"email": "not-an-email", "password": "secret12", "full_name": "Test"},
    )
    assert resp.status_code == 422
    assert "detail" in resp.json()


def test_register_rejects_short_password(client: TestClient) -> None:
    resp = client.post(
        "/api/v1/auth/register",
        json={"email": "short@qurany.app", "password": "123", "full_name": "Test"},
    )
    assert resp.status_code == 422


def test_register_rejects_empty_name(client: TestClient) -> None:
    resp = client.post(
        "/api/v1/auth/register",
        json={"email": "empty@qurany.app", "password": "secret12", "full_name": ""},
    )
    assert resp.status_code == 422


def test_auth_me_requires_token(client: TestClient) -> None:
    resp = client.get("/api/v1/auth/me")
    assert resp.status_code == 401
    assert "detail" in resp.json()
