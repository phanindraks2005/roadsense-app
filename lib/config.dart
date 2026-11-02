/// App-wide settings.
///
/// [apiBaseUrl] depends on where the backend runs:
///   - Android emulator, backend on this machine: http://10.0.2.2:8000
///   - Physical phone on the same Wi-Fi: http://<laptop-LAN-IP>:8000
///     (start uvicorn with --host 0.0.0.0 so it accepts LAN connections)
///   - Deployed backend: its public HTTPS URL
class AppConfig {
  static const String apiBaseUrl = "http://10.0.2.2:8000";

  // How often a GPS reading is saved + sent to the backend.
  static const Duration readingInterval = Duration(seconds: 1);

  // How far (meters) the app looks for named places around you.
  static const int nearbyPlacesRadiusMeters = 500;

  // Debounce for the nearby-places lookup so it isn't fired on every
  // tiny GPS update.
  static const Duration nearbyPlacesDebounce = Duration(seconds: 1);

  // Distance (meters) within which the "Speed Bump Ahead" banner is shown.
  // Kept wide so bumps are visible on the map well before you reach them.
  static const double bumpWarningRadiusMeters = 5000;

  // Voice alerts use their own, shorter distances than the banner.
  // First announcement when within this many meters:
  static const double voiceAlertRadiusMeters = 400;

  // Final "bump now" announcement when within this many meters:
  static const double voiceAlertCloseMeters = 60;
}
