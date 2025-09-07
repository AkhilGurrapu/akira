# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

fabisy is a Flutter mobile application that provides Make Yourself Fabulous functionality for Indian traditional wear (sarees, jewelry, lehengas) using AI. The app integrates Pinterest content via Scrape Creators API and uses Google's Vertex AI Gemini 2.5 Flash Image Preview for AI-powered Make Yourself Fabulous generation.

## Core Commands

### Development
```bash
flutter run                    # Run the app in development mode
flutter pub get               # Install/update dependencies
flutter clean                 # Clean build artifacts
flutter pub upgrade           # Upgrade dependencies
```

### Building
```bash
flutter build apk            # Build Android APK
flutter build ios            # Build iOS (requires Xcode)
flutter build web            # Build for web
```

### Analysis & Testing
```bash
flutter analyze              # Run static analysis
flutter test                 # Run unit/widget tests
flutter test test/widget_test.dart  # Run specific test
```

## Architecture Overview

### State Management Pattern
- **GetX**: Primary state management with reactive controllers
- **Hive**: Local storage for favorites persistence
- **Obx Widgets**: Real-time reactive UI updates

### Core Services Integration
- **Vertex AI Gemini**: AI try-on generation with both local assets and Pinterest URLs
- **Pinterest API**: Fashion content via Scrape Creators service
- **Image Processing**: Multi-source image handling (camera, gallery, web URLs)

### Key Controllers
- `HomeController` (`lib/controllers/home_controller.dart`): Manages home screen state, favorites, Pinterest content loading
- `SearchController` (`lib/controllers/search_controller.dart`): Handles catalog/search functionality

### Core Services
- `GeminiService` (`lib/services/gemini_service.dart`): Vertex AI integration with dual methods:
  - `sendRequest()`: For local asset-based try-on
  - `sendRequestWithUrl()`: For Pinterest URL-based try-on
- `ScrapeCreatorsPinterestService` (`lib/services/scrape_creators_pinterest_service.dart`): Pinterest API integration with fallback mock data

### Screen Architecture
- `MainNavigation` (`lib/screens/main_navigation.dart`): Bottom navigation controller
- `UpdatedMobileHomeScreen` (`lib/screens/updated_mobile_home_screen.dart`): Primary home screen with Pinterest integration
- `NewCatalogScreen` (`lib/screens/new_catalog_screen.dart`): Search/catalog functionality
- `TryOnScreen` (`lib/screens/try_on_screen.dart`): AI try-on canvas and generation

## Environment Configuration

Required environment variables in `.env`:
```env
GOOGLE_PROJECT_ID=your-google-project-id    # Google Cloud project for Vertex AI
VERTEX_AI_REGION=global                     # Use "global" or specific region
SCRAPE_CREATORS_API_KEY=your-api-key       # Pinterest API (optional - has fallback)
```

Required file: `service-account-key.json` at repository root with Vertex AI permissions.

## Development Patterns

### Favorites System
- Bidirectional sync between Home and Catalog screens
- Hive storage persistence across app restarts  
- Real-time UI updates via GetX reactive patterns

### Image Handling
- Pinterest images: URL-based processing via `sendRequestWithUrl()`
- Local catalog: Asset-based processing via `sendRequest()`
- Drag-and-drop functionality for both image sources

### Error Handling
- Graceful Pinterest API fallbacks to mock data
- Network error handling with user feedback
- Vertex AI error handling with detailed error messages

## Key Dependencies

### State & Storage
- `get: ^4.6.6` - State management
- `hive: ^2.2.3` + `hive_flutter: ^1.1.0` - Local storage

### AI & API Integration  
- `googleapis_auth: ^1.6.0` - Google Cloud authentication
- `http: ^1.2.1` - HTTP requests
- `flutter_dotenv: ^5.1.0` - Environment variables

### UI & Media
- `cached_network_image: ^3.3.1` - Pinterest image caching
- `image_picker: ^1.0.7` - Camera/gallery access
- `share_plus: ^10.0.2` - Result sharing

## Common Tasks

### Adding New Pinterest Categories
1. Update `categories` list in `HomeController`
2. Add search terms in `ScrapeCreatorsPinterestService.searchByCategory()`
3. Update mock data fallbacks if needed

### Extending AI Prompts
- Modify prompts in `TryOnScreen` for different try-on styles
- Indian traditional wear prompts are specialized in `GeminiService`

### Adding New Screens
- Follow existing pattern with GetX controllers
- Use `MainNavigation` for bottom tab integration
- Implement favorites sync if displaying fashion items

Please follow the "Explore, Plan, Code, Test" workflow when you start.

Explore
First, use parallel subagents to find and read all files that may be useful for implementing the ticket, either as examples or as edit targets. The subagents should return relevant file paths, and any other info that may be useful.

Plan
Next, think hard and write up a detailed implementation plan. Don't forget to include tests, lookbook components, and documentation. Use your judgement as to what is necessary, given the standards of this repo.

If there are things you are not sure about, use parallel subagents to do some web research. They should only return useful information, no noise.

If there are things you still do not understand or questions you have for the user, pause here to ask them before continuing.

Code
When you have a thorough implementation plan, you are ready to start writing code. Follow the style of the existing codebase (e.g. we prefer clearly named variables and methods to extensive comments). Make sure to run our autoformatting script when you're done, and fix linter warnings that seem reasonable to you.

Test
Use parallel subagents to run tests, and make sure they all pass.

If your changes touch the UX in a major way, use the browser to make sure that everything works correctly. Make a list of what to test for, and use a subagent for this step.

If your testing shows problems, go back to the planning stage and think ultrahard.
Local development should be separate and easy without effecting the production snowflake deployment which works.