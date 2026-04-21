# Secrets setup (API keys)

1. In Finder or Terminal, duplicate the template:
   - **Terminal:** `cp LaunchBox/Resources/Secrets.sample.plist LaunchBox/Resources/Secrets.plist`
2. Open `Secrets.plist` in Xcode and replace placeholders:
   - `API_BASE_URL` — your REST API root URL
   - `ONE_SIGNAL_APP_ID` — from the OneSignal dashboard (after adding their SDK)
   - `PRIVACY_POLICY_URL` / `TERMS_URL` — public URLs for Settings links
3. `Secrets.plist` is listed in `.gitignore` — do not commit real keys.

The app reads keys at runtime via `Secrets` in `Core/Secrets.swift`.
