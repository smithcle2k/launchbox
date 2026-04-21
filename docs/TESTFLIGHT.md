# TestFlight and App Store release

## Prerequisites (this Mac / Xcode)

- **Xcode 26+** (or your current toolchain): open the project with **Cmd+O** in Xcode, select the `Launchbox.xcodeproj` workspace.
- **Apple ID** and **Developer Program** membership: enable **iCloud** and **Push Notifications** for the app ID in the [Apple Developer portal](https://developer.apple.com) so provisioning profiles include your entitlements.
- In **Signing & Capabilities** for the `LaunchBox` target: ensure **iCloud (CloudKit)**, **Push Notifications**, and **App Groups** (`group.com.csmith.LaunchBox`) are enabled. Repeat for the `WhoseTurnWidget` target for **App Groups** only.

## Archive and upload

1. Connect an **Any iOS Device (arm64)** or use **Product → Archive** from the **LaunchBox** scheme.
2. In the **Organizer**: **Distribute App** → **TestFlight** / **App Store Connect**.
3. In App Store Connect: set **App Privacy** to *Data not collected* (matches the privacy manifest in the app), add build notes, and submit to **External Test** when ready (Beta App Review for first time).

## One-week external test (about three households)

- Invite 2–3 testers (family/roommates) with separate Apple IDs.
- Run: share household → mark chores on two devices → confirm **History** and **housemate notification** (if enabled) behave as expected.
- Track crashes in **Xcode Organizer** and optional **Feedback** in TestFlight.

The automated **Upload TestFlight build** step cannot be done from the repo without your signing credentials; use the steps above on your machine.
