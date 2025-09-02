# Apify Pinterest Integration Setup

## Overview
The Akira app now uses Apify's Pinterest Image Downloader API to fetch fashion images for the catalog section. This provides better access to Pinterest images without needing direct Pinterest API access.

## Setup Instructions

### 1. Get Apify API Token
1. Go to [Apify.com](https://apify.com)
2. Create a free account or sign in
3. Navigate to Settings > Integrations
4. Copy your API token

### 2. Configure Environment Variables
Add the following to your `.env` file:

```env
# Google Cloud Configuration for Gemini AI
GOOGLE_PROJECT_ID=your-google-project-id
VERTEX_AI_REGION=global

# Apify API Configuration
APIFY_API_TOKEN=your-apify-api-token
```

### 3. API Endpoints Used

The app uses these Apify endpoints:

#### Synchronous Search (Default)
```
POST https://api.apify.com/v2/acts/easyapi~pinterest-image-downloader/run-sync-get-dataset-items?token=***
```

#### Asynchronous Search (Optional)
```
POST https://api.apify.com/v2/acts/easyapi~pinterest-image-downloader/runs?token=***
GET https://api.apify.com/v2/acts/easyapi~pinterest-image-downloader/runs/{runId}/dataset/items?token=***
```

## Request Parameters

The app sends these parameters to Apify:

```json
{
  "searchQuery": "saree",
  "maxPins": 25,
  "downloadImages": false,
  "outputFormat": "json"
}
```

## Expected Response Format

Apify returns data in this format:

```json
[
  {
    "id": "pin_id",
    "image_url": "https://...",
    "title": "Pin title",
    "description": "Pin description",
    "width": 564,
    "height": 564,
    "pin_url": "https://pinterest.com/pin/...",
    "source_url": "https://..."
  }
]
```

## Fallback Behavior

If Apify API is not configured or fails:
1. App shows a message about using mock data
2. Displays Unsplash fashion images as fallback
3. All save/catalog functionality still works
4. Users can still use drag & drop with mock images

## Benefits of Apify Integration

1. **No Pinterest API Keys**: No need for Pinterest developer account
2. **Better Image Quality**: Access to high-resolution Pinterest images
3. **Search Functionality**: Real search results based on user queries
4. **Reliable Service**: Apify handles Pinterest API complexities
5. **Cost Effective**: Apify free tier provides good quota for testing

## Testing

To test the integration:

1. Add your Apify token to `.env`
2. Run the app: `flutter run`
3. Navigate to Catalog tab
4. Search for "saree", "jewelry", etc.
5. Save images using the heart icon
6. Check that saved images appear in Home catalog

## Troubleshooting

### No Images Loading
- Check that `APIFY_API_TOKEN` is set in `.env`
- Verify token is valid in Apify dashboard
- Check console logs for API errors

### Slow Loading
- Use async search methods for large queries
- Reduce `maxPins` parameter for faster results
- Consider caching results locally

### API Quota Exceeded
- Apify free tier has usage limits
- Upgrade to paid plan if needed
- Implement request caching to reduce API calls

## Code Structure

```
lib/services/pinterest_service.dart
├── PinterestImage class (data model)
├── searchImages() - Synchronous search
├── startAsyncSearch() - Start async search
├── getAsyncSearchResults() - Get async results
└── _getMockImages() - Fallback mock data
```
