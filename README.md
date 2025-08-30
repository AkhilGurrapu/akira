# Akira – Virtual Indian Wear Try‑On (Flutter + Vertex AI Gemini)

Akira lets users virtually try on authentic Indian traditional dresses and jewelry by uploading a photo and dragging catalog items onto it. The app calls Vertex AI Gemini to generate realistic overlays and provides an interactive canvas to position, remove, and export results.

## Features

- Drag‑and‑drop try‑on for sarees and jewelry with curated prompts
- Gemini 2.5 Flash Image Preview via Vertex AI (service account auth)
- Precise placement with local coordinates and bounds clamping
- Draggable overlays with long‑press to remove
- Download/share the composed image (RepaintBoundary capture)
- Clean, responsive UI with a catalog side panel

## Project Structure

```text
lib/
  main.dart                     # App entry, loads .env, routes to Home
  screens/
    home_screen.dart            # Upload/Camera entry screen
    try_on_screen.dart          # Canvas, drag target, overlay logic, export
  services/
    gemini_service.dart         # Vertex AI Gemini generateContent requests
  widgets/
    side_panel.dart             # Catalog tabs, draggable items
  models/
    catalog_item.dart           # CatalogItem model + dress/jewelry catalogs
gemini-2.5-flash-image-preview
assets/images/{saree,jewelry}   # Local catalog images
```

## Setup

1) Prereqs
- Flutter 3.4+ and Dart 3+
- A Google Cloud project with Vertex AI API enabled
- A service account with at least: Vertex AI User, Service Account Token Creator

2) Secrets and env
- Place `service-account-key.json` at the repository root
- Create a `.env` file in the root:

```env
GOOGLE_PROJECT_ID=your-project-id
VERTEX_AI_REGION=global   # works for our setup; us-central1 also supported
```

3) Dependencies

```bash
flutter pub get
```

Key packages used: `googleapis_auth`, `flutter_dotenv`, `image_picker`, `share_plus`, `path_provider`, `provider`.

## Running

```bash
flutter run
```

On first run, do a full restart so `.env` and assets load.

## Usage

1. From Home, upload or capture a photo
2. Drag an item from the right catalog onto your photo
3. Wait for generation, then drag the overlay to fine‑tune placement
4. Long‑press an overlay to remove it
5. Tap Download to share/save the composed image

## Gemini Integration

- Model: `gemini-2.5-flash-image-preview`
- Endpoint host:
  - `aiplatform.googleapis.com` when `VERTEX_AI_REGION=global`
  - `{region}-aiplatform.googleapis.com` for regional (e.g., `us-central1`)
- Request shape (high level):
  - `contents[0].parts`: prompt text + `inlineData` for user image + `inlineData` for catalog image
  - `generationConfig`: `responseModalities: ["TEXT","IMAGE"]`, `temperature`, `topP`, `maxOutputTokens`
  - `safetySettings`: disabled for image/text categories 

See `lib/services/gemini_service.dart` for implementation details.

## Implementation Notes

- The drag target computes local coordinates via a `GlobalKey` to place overlays accurately within canvas bounds.
- Overlays are clamped to the canvas; each is draggable and removable.
- Export uses `RepaintBoundary` to capture the composed result and `share_plus` to save/share.

## Troubleshooting

- Connection reset using `global`: ensure network access and try a full restart; switch to `us-central1` if needed.
- INVALID_ARGUMENT about response mime type: ensure `responseModalities` is set; `responseMimeType` should not be sent.
- Permission errors: verify the service account roles and that Vertex AI API is enabled.
- Large images: prefer <5MB input for faster, more reliable generation.


## Scripts and Assets

Assets are declared in `pubspec.yaml` under `assets/images/saree` and `assets/images/jewelry`. Update or extend the catalogs via `lib/models/catalog_item.dart`.

## Roadmap

- Pinch‑to‑zoom and rotation for overlays
- Landmark‑aware smart placement (face/neck detection)
- Multi‑item composition prompts for more coherent results
- Persist sessions and gallery
