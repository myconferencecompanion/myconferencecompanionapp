# Conference Companion

Flutter app (iOS + Android) for **NSE International Conference 2026** — Maiduguri, Borno State.

## Run locally

```bash
flutter pub get
flutter run
```

Supabase credentials: root `.env` (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`).

## What's in the app

| Area | Screens |
|------|---------|
| **Core** | Auth, Home, Activity (waitlist), More |
| **Programme** | Schedule, Session detail, Speakers |
| **Venue** | Maidguide, Map (ICC + outdoor), Directions, Nearby |
| **Hotels** | 47 delegate hotels (bundled from the official masterlist) + Supabase |
| **Concierge** | Usher, Food, Errands, My orders |
| **Social** | Chat rooms, Delegate directory, DMs |
| **Safety** | Announcements, Emergency contacts |
| **AI** | On-device conference guide |
| **Admin** | Role-gated dashboards and queues |

## Reference data

Programme/branding/hotels source: `C:\Users\Sage Trill\Music\SAGE\ORIVON EDGE\PROJECTS\NSE`

Re-extract hotels after NSE Hotels updates:

```bash
node tool/extract_hotels.mjs
```

## Design

Official NSE palette (navy, green, gold, paper) + Plus Jakarta Sans. Shared components in `lib/core/widgets/nse_ui.dart`.
