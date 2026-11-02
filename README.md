# RoadSense

An Android app that detects speed bumps from GPS speed data and warns drivers before they reach one.

The phone records location and speed once a second while you drive. A sharp drop in speed followed by a quick recovery is the signature of a speed bump; slowing for traffic or a turn looks different. The backend classifies these events and stores confirmed bumps, which every user then sees on the map.

## How it works

The system has two parts: this Flutter app and a Python backend.

**App (this repo)**

1. Streams GPS readings (timestamp, lat/lng, speed) to the backend while tracking is on.
2. Loads all known bumps and shows them on an OpenStreetMap map.
3. Shows a "Speed Bump Ahead" banner and speaks a voice alert as you approach one (first at 400 m, again at 60 m).
4. When you stop a trip, triggers bump detection on the backend and refreshes the markers with the result.
5. Shows nearby named places from the Overpass API and exports the trip as CSV.

**Backend (FastAPI, hosted on Render)**

1. Stores readings in SQLite.
2. On `POST /detect-bumps`, scans the stored readings for candidate events: a speed drop of at least 20% that recovers within 5 seconds.
3. Computes features for each event (speed before, minimum speed, drop, drop %, deceleration, recovery time, jerk) and runs them through a scikit-learn Random Forest classifier. Events above 0.70 confidence are kept.
4. Crowd validation: a bump is marked confirmed once it has been detected at least twice within 20 m.

The current model is trained on synthetic sensor data; real-world data collection is the next step.

### API used by the app

| Method | Endpoint | Purpose |
| --- | --- | --- |
| POST | `/trip-data` | Send one GPS reading |
| GET | `/bumps` | All detected bumps |
| POST | `/detect-bumps` | Run detection on uploaded trip data (called when a trip ends) |

## Tech stack

- Flutter / Dart, `flutter_map`, `geolocator`, `flutter_tts`, `share_plus`
- OpenStreetMap tiles, Overpass API
- Backend: Python, FastAPI, scikit-learn, pandas, SQLite, deployed on Render

## Running the app

Requires the Flutter SDK (Dart 3.3+) and an Android device or emulator.

```bash
git clone https://github.com/phanindraks2005/roadsense-app.git
cd roadsense-app
flutter pub get
flutter run
```

By default the app talks to the deployed backend at `https://roadsense-backend-t98l.onrender.com`. It runs on Render's free tier, so the first request after a period of inactivity can take over a minute while the server wakes up.

To use a backend running locally instead, pass its URL at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` is how the Android emulator reaches the host machine. On a physical phone, use your laptop's LAN IP and start the backend with `uvicorn main:app --host 0.0.0.0 --port 8000`.

Alert distances, the reading interval and timeouts are in `lib/config.dart`.

## Project structure

```
lib/
  config.dart        backend URL, intervals, alert distances
  models/            Bump, TripPoint
  screens/           home screen (map, tracking loop, alerts)
  services/          API client, location, Overpass, voice alerts, CSV export
  widgets/           speed card, location card, banner, control panel, markers
```
