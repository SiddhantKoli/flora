# FLORA

An Android-first Flutter prototype for collecting plant observations. It starts in guest mode and saves photos, notes, discoveries, XP, quests, and achievements on the device.

## Run

Install the Flutter and Android SDKs, then run `flutter pub get` and `flutter run` on an Android device or emulator. Run `flutter test` and `flutter analyze` to check the project.

## Current scope

- Capture one photo through the camera or select one from the library.
- Manually select from eight draft catalog entries, or save an unknown observation.
- Keep a local SQLite journal with editable notes and photo deletion.
- Earn first-discovery and capped repeat XP; claim daily and weekly quests; unlock two achievement milestones.
- Browse a searchable Plantdex with locked and discovered states.

There is no automatic species identification, vetted 1,000-entry catalog, cloud sync, or account system in this prototype. The seed catalog is illustrative and is not approved botanical content. A user's selection is not expert verification. Do not use this app to determine edibility, safety, or medical use.

Before release, validate a local model checkpoint and license, map its labels to the curated catalog, review content and imagery rights, add opt-in online verification through a secured backend, and test real smartphone photos and Android devices.
