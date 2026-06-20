# Qurany — Technical Plan

## Motivation
The Qurany project addresses the practical gap learners face when trying to obtain regular, accurate feedback on Qur'anic recitation. Qualified Sheikhs are limited in availability and geographically dispersed; existing commercial solutions restrict advanced correction features behind paywalls. Qurany aims to deliver an inclusive, high-quality, low-latency recitation feedback system that combines modern speech technologies, robust alignment algorithms, and an accessible cross-platform client to democratize recitation correction and memorization support.

## Project Summary
Qurany is a real-time recitation correction application that captures live audio, transcribes recitation, aligns the transcript with canonical Uthmani text, and highlights errors in real time. The platform also provides a full Quran reader, search, bookmarks, progress tracking, prayer times, Qibla, and daily Islamic content. The system targets Android, iOS, and Web platforms and prioritizes accuracy, low latency, and scalability.

## Key Constraints and Targets
- Real-time latency: ≤ 2 seconds end-to-end
- STT accuracy (word-level): ≥ 85% for Quranic recitation
- Alignment accuracy (verse identification): ≥ 90%
- Availability: 99% uptime target
- Scalability: support 1,000+ concurrent users (baseline)
- Security: HTTPS, OAuth2/OIDC, AES-256 at rest
- Portability: Android, iOS, Web

## Technology Recommendations

### Frontend (mobile + web)
- Framework: Flutter — single codebase for Android, iOS, and Web
- State management: Riverpod
- Audio transport: WebRTC for low-latency streaming; fallback to WebSocket frames
- Audio capture & preprocessing: flutter_sound or audio_session with platform channels for noise suppression and normalization
- Local storage: Hive (encrypted) for bookmarks and offline queuing

### Backend & Real-time
- API & gateway: TypeScript with Fastify (high throughput) or NestJS (structured) — Fastify recommended for MVP performance
- Real-time media: WebRTC SFU (e.g., Janus or mediasoup) for low-latency audio routing
- ML services: Python microservices (FastAPI) for STT integration, alignment, and validation
- STT strategy:
  1. MVP: Cloud streaming STT (Azure Speech or Google Cloud Speech-to-Text) with custom adaptation for Quranic Arabic
  2. Mid-term: Fine-tune open-source models (Whisper / Kaldi variants) and serve on GPU instances
  3. Long-term: On-device fallback (VOSK or Whisper small) for privacy/offline mode
- Alignment & validation: Python alignment module using sequence alignment and Arabic normalization

### Databases & Storage
- Primary DB: PostgreSQL (with JSONB for flexible fields)
- Cache & state: Redis (session state, partial transcriptions, pub/sub)
- Object storage: S3-compatible (AWS S3 or MinIO)
- Search: Postgres full-text + pg_trgm; Elastic only if necessary

### Authentication & Security
- Auth: Keycloak (self-hosted) or Firebase Auth (managed) for MVP speed
- Transport: HTTPS and secure WebRTC channels
- Data encryption: AES-256 for audio at rest; TLS in transit

### DevOps & Observability
- Containerization: Docker; orchestration: Kubernetes or Cloud Run
- CI/CD: GitHub Actions; mobile releases via Fastlane
- IaC: Terraform
- Monitoring: Prometheus + Grafana; error tracking: Sentry

## System Architecture (component overview)
- Flutter client: captures audio → preprocess → stream via WebRTC
- Streaming gateway (Fastify / Node) + SFU: receives audio, forwards to STT
- STT service (cloud or on-prem): streaming transcripts
- Alignment & validation service (Python): aligns transcripts to canonical text, classifies errors
- API service: user data, session CRUD, history
- Storage: Postgres, Redis, S3
- Workers: background processing for offline uploads, analytics, and model training

## Core Data Model (concise)
- `users` (id, email, display_name, roles, created_at)
- `verses` (surah, ayah, text_uthmani, normalized_text)
- `recitation_sessions` (id, user_id, start_ts, end_ts, mode)
- `recitation_chunks` (session_id, chunk_ts, audio_path, partial_transcript, final_transcript, status)
- `recitation_errors` (chunk_id, verse_ref, word_idx, error_type, correction, confidence, metadata)
- `bookmarks` (user_id, verse_ref, notes)

Indexes: GIN on normalized_text (pg_trgm), indexes on user_id and timestamps, JSONB indexes for frequent queries.

## ML & Algorithmic Details
- Arabic normalization pipeline: strip/normalize tashkeel, normalize Alef/Hamza variants, map common qira'at variants
- Streaming alignment: incremental alignment per audio chunk using edit-distance / dynamic programming; maintain rolling state to identify current verse
- Error classification: token-level alignment to detect substitution, omission, addition, and sequence errors; incorporate acoustic confidence and language-model scores for mispronunciation detection
- Training pipeline: collect consented recitations, label alignment errors, and fine-tune STT/correction models

## Phased Technical Roadmap
- Phase 0 — Prep (1–2 weeks): repo scaffold, dev infra (Postgres, Redis, MinIO), canonical Quran dataset
- Phase 1 — MVP (6–8 weeks): Flutter prototype, WebSocket streaming to Fastify gateway, cloud streaming STT, basic alignment, Postgres storage, minimal auth
- Phase 2 — Real-time polish (4–6 weeks): WebRTC SFU, freeze/timer UI, transient vs persistent error handling, qira'at normalization improvements
- Phase 3 — Offline & on-device (6–10 weeks): local queueing + background sync, on-device inference prototype (VOSK/Whisper small)
- Phase 4 — Production & scaling (4–6 weeks): Keycloak/OIDC, containerize & deploy to K8s, autoscaling, monitoring, backups
- Phase 5 — Model refinement (ongoing): labeled data collection, fine-tuning, replace cloud STT with self-hosted inference where cost-effective

## CI/CD & Testing Strategy
- Unit & integration tests: `flutter_test`, `pytest`, `jest`
- E2E: Flutter `integration_test` for mobile; Playwright for admin/web
- Pipelines: GitHub Actions workflows for mobile build, backend CI, deployment
- Release automation: Fastlane for app store deployments

## Costs, Trade-offs, and Notes
- Cloud STT offers best initial accuracy but incurs recurring costs—plan to migrate to fine-tuned self-hosted models to reduce cost and preserve privacy.
- WebRTC + SFU provides lowest latency but increases infra complexity; WebSocket fallback reduces complexity at cost of higher latency.
- Flutter speeds cross-platform development and reduces maintenance overhead.

## Immediate Decisions Needed
1. Confirm frontend: Flutter (mobile + web)
2. Confirm streaming: WebRTC (SFU) with WebSocket fallback
3. Choose MVP STT provider: Azure Speech, Google Cloud Speech, or Other

## Next Steps (on confirmation)
- Produce a component diagram and starter repo layout.
- Create GitHub Actions CI templates and Docker Compose for local dev.

---
Generated based on `Qurany_Midyear_documentation.pdf` and the project's requirements.
