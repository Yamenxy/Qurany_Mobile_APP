# Manual smoke checklist (category E)

Run before demos / after wiring changes. Tick each box when pass.

**Prerequisites:** Backend running (`python main.py` from `backend/`), phone and laptop on same network, phone has internet for public APIs.

Replace `<LAPTOP_IP>` with your Wi‑Fi IPv4 (e.g. `172.31.78.29`).

---

## Network & backend

- [ ] Phone browser: `http://<LAPTOP_IP>:8000/health` → JSON `"status":"ok"`
- [ ] Phone browser: `http://<LAPTOP_IP>:8000/docs` opens Swagger
- [ ] Windows Firewall allows Python / port 8000 on private network

## Recitation backend (your models)

- [ ] Swagger `POST /api/v1/analyze-text` — Surah 78, Hafs, perfect text → score 100%
- [ ] Swagger `POST /api/v1/analyze-text` — Surah 2, `riwayah=bazzi`, one full ayah → score ≥ 85%
- [ ] First `POST /api/v1/analyze` (audio) completes without 500 (GPU/CPU load acceptable)

## Flutter app (after wiring)

- [ ] App launches; home screen loads
- [ ] Quran / mushaf loads (needs internet — AlQuran Cloud)
- [ ] Prayer times banner loads (needs internet — Aladhan)
- [ ] Register + login against laptop backend (`QURANY_API_BASE=http://<LAPTOP_IP>:8000`)
- [ ] Record one ayah → server analysis → results screen (no raw 404/500 text shown)
- [ ] Wrong password login → Arabic error, not HTTP status code
- [ ] Airplane mode → friendly offline message, no crash

## Regression quick pass

- [ ] Bookmarks add/remove persists after app restart
- [ ] Recitation history saves a session
- [ ] Bazzi qira'ah path uses Bazzi reference (Surah 2 only)

---

## Notes

| Date | Tester | Build / commit | Failures |
|------|--------|----------------|----------|
|      |        |                |          |
