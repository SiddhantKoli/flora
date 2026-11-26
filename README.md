# FLORA

FLORA is an Android-first Flutter prototype for keeping a personal log of plants you notice. It runs in guest mode and stores observations and game progress locally on the device.

## Run locally

Install Flutter and the Android SDK, then run:

```sh
flutter pub get
flutter run
```

## What the app currently does

- Opens on the Plantdex and provides a center **Add a plant** camera action. New observations require a photo taken in the in-app Atomic Purple FLORA Cam; gallery imports are unavailable. The camera has a square viewfinder, front/rear switching, five subtle digicam-inspired looks in the gear menu, and a shutter. The square frame is only a preview; captures keep their full aspect ratio.
- Shows the selected photo for review. You can retake it, search the small sample catalog and manually choose a plant, or save the photo as unknown with an optional note. When a camera look is applied, review lets you save the edited copy or the original. If saving fails or the photo is a duplicate, review stays open with a visible recovery message.
- On first run, explains camera capture, manual naming, and local storage, with a direct path to the first plant. A save confirmation shows the earned XP or saved count and offers a Journal shortcut.
- Saves photos, notes, and observations in a local journal. You can add more in-app camera photos to an existing entry, switch between them, search plant names and notes, filter unknown plants, inspect a photo full-screen with zoom, correct a manually selected plant name (including Unknown), edit notes, and delete an observation. Correcting a name updates the Plantdex without awarding XP again.
- Tracks first discoveries, capped repeat XP, daily and weekly quest progress and claims, and two achievement milestones.
- Shows a searchable Plantdex with collected and undiscovered sample entries, plus profile stats and badges.
- Exports a local FLORA backup file containing journal photos, notes, discoveries, and progress. The Profile screen can restore a backup after preview and explicit replacement confirmation. FLORA does not upload this file.
- Uses an adaptive Android launcher icon and a custom launch screen.

Plant selection is user-provided. FLORA does **not** identify plants from photos, recommend a match, or provide an identification confidence score. The sample catalog contains eight illustrative entries; it is not a reviewed or complete botanical reference. Treat selected names as personal labels, not verified identifications. Do not use FLORA to decide whether a plant is safe to eat, touch, or use as medicine.

## What is missing

- A deeper multi-step onboarding and a guided first observation walkthrough.
- A broader settings screen, display-name/avatar editing, accessibility preferences, and a clear-all-data action.
- A larger, botanically reviewed catalog with distinct, rights-cleared images or artwork for every entry.
- Automatic photo identification, suggested matches, confidence values, and expert verification.
- Cloud backup and account sign-in. Exporting and restoring a local backup file can transfer data, but unsaved local data may be lost on uninstall or device loss.
- Social features, notifications, and a more developed progression and reward system.

The UI has Plantdex, Journal, Quests, and profile tabs with a soft neutral palette, bright accents, original simple illustrations, and small entrance animations. Settings are not implemented yet.

The Atomic Purple camera shell recreates the supplied reference with Flutter widgets and vector painting: layered acrylic edges, circuitry, chips, screws, raised controls, sticker, and light reflections. No screenshot is used as a camera overlay; the square center remains a live camera preview. Camera looks are creative effects inspired by the general feel of compact digital cameras. They are not official Canon or Sony modes. The live preview approximates the saved treatment; grain appears only after capture. Camera behavior and image processing still need testing on physical devices, especially lower-end phones.

## Screenshots

<img src="docs/screenshots/camera.png" alt="Atomic Purple FLORA Cam" width="220" />
<img src="docs/screenshots/plantdex.png" alt="Plantdex" width="220" />
<img src="docs/screenshots/journal.png" alt="Journal" width="220" />
<img src="docs/screenshots/quests.png" alt="Quests" width="220" />
<img src="docs/screenshots/profile.png" alt="Profile" width="220" />

## Before release

Review the catalog and all plant safety language with qualified botanical sources, confirm imagery rights, test backup and restore with large real journals and on physical Android devices, and test the camera with real photos. Any future identification feature needs a validated model and a clear way to communicate uncertainty.
