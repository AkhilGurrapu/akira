# fabisy – Virtual Indian Wear Try‑On (Flutter + Vertex AI Gemini + Pinterest API)

fabisy lets users virtually try on authentic Indian traditional wear including sarees and jewelry. The app integrates Pinterest's fashion content through Scrape Creators API and uses Vertex AI Gemini to generate realistic try-on experiences with drag-and-drop functionality.

## 🌟 Features

### Core Functionality
- **Dynamic Pinterest Integration**: Real-time Indian fashion content from Pinterest
- **Drag & Drop Try-On**: Both Pinterest items and local catalog items are draggable
- **AI-Powered Generation**: Gemini 2.5 Flash Image Preview via Vertex AI
- **Favorites System**: Heart-based favoriting across all screens with persistence
- **Indian Fashion Focus**: Specialized search for Indian sarees and traditional jewelry

### User Experience
- **Dual Content Sources**: Pinterest trending items + local classic collection
- **Smart UI**: Original home design with seamless Pinterest integration
- **Mobile Optimized**: Bottom navigation with Home, Catalog, Video, Profile
- **Real-time Loading**: Pinterest samples load in background while app remains functional

## 🏗️ Architecture

### App Structure
```
lib/
├── main.dart                           # App entry with GetX + Hive initialization
├── controllers/
│   ├── home_controller.dart           # Home state management with favorites
│   └── search_controller.dart         # Search functionality (renamed for Flutter compatibility)
├── screens/
│   ├── updated_mobile_home_screen.dart # Main home with Pinterest integration
│   ├── new_catalog_screen.dart        # Search/discovery screen
│   ├── main_navigation.dart           # Bottom navigation controller
│   └── try_on_screen.dart            # AI try-on canvas
├── services/
│   ├── scrape_creators_pinterest_service.dart # Pinterest API integration
│   └── gemini_service.dart           # Vertex AI Gemini (local + URL support)
├── models/
│   └── catalog_item.dart             # Legacy local catalog models
└── widgets/
    └── side_panel.dart              # Legacy widget (preserved)
```

### State Management
- **GetX**: Reactive state management for UI updates
- **Hive**: Local storage for favorites persistence
- **Obx Widgets**: Real-time UI updates for Pinterest content

## 🔧 Setup

### Prerequisites
- Flutter 3.4+ and Dart 3+
- Google Cloud project with Vertex AI API enabled
- Service account with: Vertex AI User, Service Account Token Creator
- Scrape Creators API account (optional - has fallback)

### Environment Configuration
Create a `.env` file in the root:

```env
# Google Cloud Configuration for Gemini AI
GOOGLE_PROJECT_ID=your-google-project-id
VERTEX_AI_REGION=global

# Pinterest Integration (Optional)
SCRAPE_CREATORS_API_KEY=your-scrape-creators-api-key
```

### Service Account Setup
Place `service-account-key.json` at the repository root with proper Vertex AI permissions.

### Dependencies Installation
```bash
flutter pub get
```

**Key packages:**
- `get: ^4.6.6` - State management
- `hive: ^2.2.3` + `hive_flutter: ^1.1.0` - Local storage
- `cached_network_image: ^3.3.1` - Image caching
- `googleapis_auth`, `flutter_dotenv`, `image_picker`, `share_plus`

## 🚀 Running the App

```bash
flutter run
```

The app works immediately with mock data. Add your Scrape Creators API key for real Pinterest content.

## 📱 Usage Guide

### Home Screen
1. **Upload/Capture Photo**: Use Camera or Upload buttons
2. **Browse Categories**: 
   - **Dresses Tab**: Indian Sarees from Pinterest
   - **Jewelry Tab**: Traditional Indian Jewelry from Pinterest  
   - **Favorites Tab**: Your favorited items
3. **Try-On Methods**:
   - **Drag & Drop**: Drag any item onto your photo
   - **Try-On Button**: Direct try-on with image picker modal
4. **Favorites**: Heart any item to save to favorites

### Catalog/Search Screen
1. **Search**: Type fashion terms for Pinterest results
2. **Category Filter**: Filter by saree, jewelry, dresses, etc.
3. **Heart Items**: Add to favorites (synced with home)
4. **Try-On**: Direct try-on functionality

### AI Try-On Process
1. Upload/capture your photo
2. Drag Pinterest item or local catalog item onto photo
3. AI generates realistic overlay using Gemini 2.5 Flash
4. Download/share the result

## 🔌 Pinterest Integration

### Scrape Creators API
- **Base URL**: `https://api.scrapecreators.com/v1/pinterest`
- **Endpoints Used**: `/search` for category-based queries
- **Search Strategy**: Indian-focused fashion terms

### Search Categories & Terms
```dart
'dresses': [
  'indian saree mannequin display',
  'traditional indian saree model',
  'silk saree on mannequin',
  'designer indian saree display',
  // ... more Indian saree terms
],
'jewelry': [
  'indian gold jewelry set',
  'traditional kundan jewelry',
  'indian bridal jewelry gold',
  'diamond indian jewelry',
  // ... more Indian jewelry terms
]
```

### Fallback System
- **Mock Data**: High-quality Unsplash fashion images
- **Graceful Degradation**: App fully functional without API key
- **Error Handling**: Network failures don't break the app

## 🎨 UI/UX Design

### Home Screen Features
- **Original Design Preserved**: Maintains familiar UI layout
- **Pinterest Integration**: Seamless blend with existing interface
- **Loading States**: Shows "Loading Indian Sarees..." while fetching
- **Favorites Count**: Top-right corner shows total favorites
- **Drag Indicators**: Visual cues for draggable items

### Catalog Screen Features
- **Real-time Search**: Live Pinterest search results
- **Category Tabs**: All, Saree, Jewelry, Dresses, etc.
- **Grid Layout**: Optimized for mobile browsing
- **Heart Favoriting**: Instant feedback with animations

## 🔧 Technical Implementation

### Gemini AI Integration
- **Local Assets**: Original drag-and-drop with local images
- **Pinterest URLs**: New `sendRequestWithUrl()` method for Pinterest images
- **Prompts**: Specialized prompts for Indian traditional wear
- **Error Handling**: Comprehensive error management

### State Synchronization
- **Favorites Sync**: Perfect sync between Home and Catalog screens
- **Real-time Updates**: Obx widgets update instantly
- **Persistence**: Hive storage maintains favorites across app restarts

### Performance Optimizations
- **Image Caching**: CachedNetworkImage for Pinterest content
- **Lazy Loading**: Pinterest samples load in background
- **Memory Management**: Proper disposal of controllers and services

## 🛠️ Troubleshooting

### Pinterest API Issues
- **No API Key**: App works with mock data automatically
- **Rate Limits**: Graceful fallback to cached/mock content
- **Network Issues**: Offline-first approach with local fallbacks

### Gemini AI Issues
- **Connection Issues**: Check service account permissions
- **Large Images**: Optimize to <5MB for better performance
- **Regional Settings**: Use `global` or specific regions like `us-central1`

### App Performance
- **Memory Usage**: Controllers properly disposed
- **Image Loading**: Cached network images prevent redundant downloads
- **State Management**: GetX provides efficient reactive updates

## 📂 File Organization

### Core Files (Active)
- `updated_mobile_home_screen.dart` - Main home screen
- `new_catalog_screen.dart` - Search/catalog functionality
- `scrape_creators_pinterest_service.dart` - Pinterest API
- `home_controller.dart` - Home state management
- `search_controller.dart` - Search functionality

### Legacy Files (Preserved)
- `mobile_home_screen.dart` - Original home implementation
- `home_screen.dart` - Desktop version
- `catalog_screen.dart` - Original catalog
- `pinterest_service.dart` - Old Apify integration

## 🚀 Future Roadmap

### Planned Enhancements
- **Advanced Search**: More Pinterest search filters
- **User Profiles**: Personal fashion preferences
- **Social Features**: Share try-ons with friends
- **AR Integration**: Real-time camera try-on
- **ML Recommendations**: AI-powered fashion suggestions

### Technical Improvements
- **Offline Mode**: Better offline functionality
- **Performance**: Further optimization for low-end devices
- **Accessibility**: Enhanced accessibility features
- **Analytics**: User behavior tracking

## 📄 License

This project showcases Flutter + AI integration for fashion technology. The Pinterest integration respects API terms of service and includes proper fallback mechanisms.

---

**Made with ❤️ using Flutter, Vertex AI Gemini, and Pinterest API**