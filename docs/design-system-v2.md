# FLORA visual direction: Field Notes

FLORA is a camera-first plant journal. Its interface should feel like a modern
photo zine made for noticing the city and the outdoors. Plant photos lead;
labels, progress, and controls support the photos.

## Tokens

| Role | Color |
| --- | --- |
| Paper | `#F2F4F1` |
| Ink | `#101B1A` |
| Surface | `#FFFFFF` |
| Midnight | `#102B2C` |
| Signal blue | `#345BFF` |
| Camera coral | `#FF6A4C` |
| Soft mint | `#CEE7D5` |
| Line | `#D7DFDA` |
| Secondary text | `#53625E` |

Space Grotesk carries display text and section headings. DM Sans carries body
copy, controls, and form labels. Both font files are bundled so the UI works
offline; their SIL Open Font License notices live beside the assets.

## Layout

- The collection opens with a full-bleed editorial leaf image and the latest
  journal action. Generated artwork is decorative and never represents a
  verified species.
- Catalog entries are a concise index, with clearly separate collected and
  sample states. The user's own photos get the largest visual space.
- Journal is a vertical photo story: large image, plant name, dated visits.
- Quests are optional progress strips, with a clear next level and no pressure.
- Profile reads like a field notebook cover, then recent plants and controls.
- Camera uses a quiet matte housing and generous square live viewfinder.
  The shutter and review flow remain explicit: **Add a plant**, manual naming.

```text
Plantdex                 Journal                  Camera
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ FLORA        02/08│     │ Your field notes │     │  ←  FIELD CAMERA │
│ ╔══════════════╗ │     │ ┌──────────────┐ │     │ ┌──────────────┐ │
│ ║ leaf image   ║ │     │ │ plant photo  │ │     │ │ live preview │ │
│ ║ Add a plant  ║ │     │ └──────────────┘ │     │ └──────────────┘ │
│ ╚══════════════╝ │     │ Name / last seen │     │ looks / shutter  │
│ Browse species   │     │ dated timeline   │     │ review next      │
└──────────────────┘     └──────────────────┘     └──────────────────┘
```

## Motion

Use `flutter_animate` for brief, action-led transitions: shutter feedback,
saved-state reveal, tab indicator, and opening a plant story. Most content
should appear immediately. Motion must stop when Android or FLORA requests
reduced motion. Typical response: 120–240 ms; a save celebration may run up to
450 ms. Keep content and touch targets in stable positions.

## Guardrails

- Keep touch targets at least 48 dp and text readable at larger system sizes.
- Use semantic labels for icon buttons and never rely on color alone.
- Preserve photo color and detail; effects are creative treatments only.
- Keep camera images local. Generated artwork is a visual accent, not a plant
  identification reference.
- The old cream/forest/lime card layouts and Atomic Purple camera shell do not
  appear in the new UI.

Decorative hero prompt: editorial macro botanical still life with a glossy
dark green leaf, visible veins, droplets, cobalt reflection, warm coral edge,
deep midnight teal background, negative space for UI copy, no text or logo.
Generated with the built-in image generation tool.
