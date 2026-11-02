/// ============================================================
/// APP CONFIGURATION
/// ============================================================
///
/// IMPORTANT — set this before running the app:
///
///   • Android Emulator + backend running on your laptop:
///       use "http://10.2.0.2:8000"  --> actually use 10.0.2.2
///       (10.0.2.2 is the emulator's alias for your host machine)
///
///   • Real phone + backend running on your laptop (same Wi-Fi):
///       use "http://<your-laptop-LAN-IP>:8000"
///       e.g. "http://192.168.1.42:8000"
///       (find it with `ipconfig` on Windows or `ifconfig`/`ip a` on
///       Mac/Linux — do NOT use 127.0.0.1, that means "this phone")
///
///   • Backend deployed to a server:
///       use that server's URL, e.g. "https://roadsense-api.onrender.com"
///
/// Also make sure your FastAPI backend is started with:
///   uvicorn main:app --host 0.0.0.0 --port 8000
/// (not the default 127.0.0.1-only binding) so it accepts connections
/// from other devices on the network.
class AppConfig {
  static const String apiBaseUrl = "http://10.0.2.2:8000";

  // How often a GPS reading is saved + sent to the backend.
  static const Duration readingInterval = Duration(seconds: 1);

  // How far (meters) the app looks for named places around you.
  static const int nearbyPlacesRadiusMeters = 500;

  // Debounce for the nearby-places lookup so it isn't fired on every
  // tiny GPS update.
  static const Duration nearbyPlacesDebounce = Duration(seconds: 1);

  // Distance (meters) within which the "Speed Bump Ahead" banner is
  // shown. The original web prototype used 5000m (5km) — that's kept
  // here for parity, but 300-800m reads more realistically as an
  // "ahead" warning if you want to tune it for the demo.
  static const double bumpWarningRadiusMeters = 5000;

  // Voice alert distances — separate from the banner radius above so the
  // spoken warning stays useful (announcing "bump ahead" 5km out would be
  // useless). First announcement when within this many meters:
  static const double voiceAlertRadiusMeters = 400;

  // Final "bump now" announcement when within this many meters:
  static const double voiceAlertCloseMeters = 60;
}
