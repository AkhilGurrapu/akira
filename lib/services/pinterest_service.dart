import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PinterestImage {
  final String id;
  final String url;
  final String title;
  final String description;
  final int width;
  final int height;
  final String originalUrl;
  bool isSaved;

  PinterestImage({
    required this.id,
    required this.url,
    required this.title,
    required this.description,
    required this.width,
    required this.height,
    required this.originalUrl,
    this.isSaved = false,
  });

  factory PinterestImage.fromApifyJson(Map<String, dynamic> json, String searchQuery) {
    // Parse Apify Pinterest Image Downloader response
    final result = json['result'] ?? json;
    final medias = result['medias'] as List? ?? [];
    
    // Get the best quality image (prefer originals, then 564x, then 236x)
    String imageUrl = '';
    int width = 564;
    int height = 564;
    
    if (medias.isNotEmpty) {
      // Sort by quality preference: originals > 564x > 236x
      final sortedMedias = List.from(medias);
      sortedMedias.sort((a, b) {
        String urlA = a['url'] ?? '';
        String urlB = b['url'] ?? '';
        
        if (urlA.contains('originals')) return -1;
        if (urlB.contains('originals')) return 1;
        if (urlA.contains('564x')) return -1;
        if (urlB.contains('564x')) return 1;
        return 0;
      });
      
      final bestMedia = sortedMedias.first;
      imageUrl = bestMedia['url'] ?? '';
      width = bestMedia['width']?.toInt() ?? 564;
      height = bestMedia['height']?.toInt() ?? 564;
    }
    
    // Generate appropriate title based on search query and ensure uniqueness
    String title = _generateFashionTitle(searchQuery, result['url']?.toString().split('/').last ?? '');
    
    return PinterestImage(
      id: result['url']?.toString().split('/').last ?? DateTime.now().millisecondsSinceEpoch.toString(),
      url: imageUrl,
      title: title,
      description: 'Beautiful $searchQuery style perfect for any occasion',
      width: width,
      height: height,
      originalUrl: result['url'] ?? '',
    );
  }
  
  // Generate fashion-appropriate titles based on search query
  static String _generateFashionTitle(String query, String id) {
    final queryLower = query.toLowerCase();
    final hash = id.hashCode.abs();
    
    final Map<String, List<String>> titleTemplates = {
      'saree': [
        'Elegant Silk Saree',
        'Traditional Cotton Saree',
        'Designer Wedding Saree',
        'Festive Party Saree',
        'Bridal Luxury Saree',
        'Classic Banarasi Saree',
        'Modern Designer Saree',
        'Royal Silk Saree'
      ],
      'jewelry': [
        'Statement Gold Necklace',
        'Diamond Earring Set',
        'Traditional Kundan Jewelry',
        'Bridal Jewelry Collection',
        'Elegant Pearl Necklace',
        'Designer Ring Set',
        'Temple Jewelry',
        'Royal Jewelry Set'
      ],
      'dress': [
        'Designer Evening Dress',
        'Casual Summer Dress',
        'Party Cocktail Dress',
        'Formal Office Dress',
        'Wedding Guest Dress',
        'Vintage Style Dress',
        'Modern Chic Dress',
        'Elegant Maxi Dress'
      ],
      'lehenga': [
        'Bridal Lehenga Choli',
        'Designer Party Lehenga',
        'Traditional Wedding Lehenga',
        'Festive Silk Lehenga',
        'Modern Fusion Lehenga',
        'Royal Embroidered Lehenga',
        'Elegant Reception Lehenga',
        'Classic Bridal Lehenga'
      ]
    };
    
    List<String> templates = titleTemplates[queryLower] ?? [
      'Stylish Fashion Item',
      'Designer Collection',
      'Elegant Fashion Piece',
      'Trendy Style Item',
      'Premium Fashion',
      'Luxury Design',
      'Fashion Statement',
      'Style Essential'
    ];
    
    return templates[hash % templates.length];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'description': description,
      'width': width,
      'height': height,
      'originalUrl': originalUrl,
      'isSaved': isSaved,
    };
  }
}

class PinterestService {
  final String _apifyBaseUrl = 'https://api.apify.com/v2/acts/easyapi~pinterest-image-downloader';
  final String? _apifyToken = dotenv.env['APIFY_API_TOKEN'];
  
  // For development - force mock data until real token is configured
  final bool _useMockData = true; // Apify API returning irrelevant images, using mock data
  
  Future<List<PinterestImage>> searchImages(String query, {int limit = 25}) async {
    // Temporarily force mock data for development
    if (_useMockData) {
      print('Using mock data for development. Set _useMockData = false in pinterest_service.dart to use real API.');
      return _getMockImages(query);
    }
    
    // Check if we have a valid Apify token (not just a placeholder)
    if (_apifyToken == null || 
        _apifyToken.isEmpty || 
        _apifyToken == 'your-apify-api-token' ||
        _apifyToken.length < 10) {
      print('Apify API token not configured properly. Using mock data.');
      print('To use real Pinterest data, add a valid APIFY_API_TOKEN to your .env file.');
      return _getMockImages(query);
    }

    try {
      final url = Uri.parse('$_apifyBaseUrl/run-sync-get-dataset-items').replace(
        queryParameters: {'token': _apifyToken},
      );

      final requestBody = {
        'searchQuery': query,
        'maxPins': limit,
        'downloadImages': false, // We only need URLs, not actual downloads
        'outputFormat': 'json',
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Handle both array response and object with items
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data['items'] != null) {
          items = data['items'] as List;
        } else if (data is Map && data['data'] != null) {
          items = data['data'] as List;
        }
        
        if (items.isNotEmpty) {
          return items
              .map((item) => PinterestImage.fromApifyJson(item, query))
              .where((image) => image.url.isNotEmpty)
              .take(limit)
              .toList();
        } else {
          print('Apify API returned empty results. Using mock data.');
          return _getMockImages(query);
        }
      } else {
        print('Apify API error: ${response.statusCode} ${response.body}');
        print('Falling back to mock data.');
        return _getMockImages(query);
      }
    } catch (e) {
      print('Error calling Apify API: $e');
      print('Falling back to mock data.');
      return _getMockImages(query);
    }
  }

  // Alternative method for faster async search (optional)
  Future<String> startAsyncSearch(String query, {int limit = 25}) async {
    if (_apifyToken == null || _apifyToken.isEmpty) {
      throw Exception('Apify API token required for async search');
    }

    try {
      final url = Uri.parse('$_apifyBaseUrl/runs').replace(
        queryParameters: {'token': _apifyToken},
      );

      final requestBody = {
        'searchQuery': query,
        'maxPins': limit,
        'downloadImages': false,
        'outputFormat': 'json',
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data']['id']; // Return run ID for later polling
      } else {
        throw Exception('Failed to start async search: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error starting async search: $e');
    }
  }

  Future<List<PinterestImage>> getAsyncSearchResults(String runId) async {
    if (_apifyToken == null || _apifyToken.isEmpty) {
      throw Exception('Apify API token required');
    }

    try {
      final url = Uri.parse('$_apifyBaseUrl/runs/$runId/dataset/items').replace(
        queryParameters: {'token': _apifyToken},
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data as List? ?? [];
        
        return items
            .map((item) => PinterestImage.fromApifyJson(item, 'fashion'))
            .where((image) => image.url.isNotEmpty)
            .toList();
      } else {
        throw Exception('Failed to get results: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting async results: $e');
    }
  }

  // Get popular search terms
  // Mock data for development when API is not available
  List<PinterestImage> _getMockImages(String query) {
    // Category-specific mock images for better user experience
    final Map<String, List<Map<String, String>>> categoryData = {
      'saree': [
        {'url': 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=400', 'title': 'Elegant Red Silk Saree'},
        {'url': 'https://images.unsplash.com/photo-1594736797933-d0b71ee5e632?w=400', 'title': 'Traditional Pink Cotton Saree'},
        {'url': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400', 'title': 'Blue Designer Saree'},
        {'url': 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=400', 'title': 'Golden Bridal Saree'},
        {'url': 'https://images.unsplash.com/photo-1574146042765-e95a5b3e8a1e?w=400', 'title': 'Green Banarasi Saree'},
        {'url': 'https://images.unsplash.com/photo-1617019114583-affb34d1b3cd?w=400', 'title': 'Purple Wedding Saree'},
        {'url': 'https://images.unsplash.com/photo-1587831990711-23ca6441447b?w=400', 'title': 'Orange Festive Saree'},
        {'url': 'https://images.unsplash.com/photo-1562788869-4ed32648eb72?w=400', 'title': 'White Party Saree'},
      ],
      'jewelry': [
        {'url': 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400', 'title': 'Gold Necklace'},
        {'url': 'https://images.unsplash.com/photo-1602173574767-37ac01994b2a?w=400', 'title': 'Diamond Earrings'},
        {'url': 'https://images.unsplash.com/photo-1506630448388-4e683c67ddb0?w=400', 'title': 'Traditional Jewelry'},
        {'url': 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=400', 'title': 'Bridal Jewelry Set'},
      ],
      'dress': [
        {'url': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400', 'title': 'Evening Dress'},
        {'url': 'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=400', 'title': 'Casual Dress'},
        {'url': 'https://images.unsplash.com/photo-1566479179817-c0678c5ce26c?w=400', 'title': 'Party Dress'},
        {'url': 'https://images.unsplash.com/photo-1516575150278-77136aed6920?w=400', 'title': 'Designer Dress'},
      ],
    };

    // Default fallback images
    final defaultData = [
      {'url': 'https://images.unsplash.com/photo-1594736797933-d0b71ee5e632?w=400', 'title': 'Fashion Item 1'},
      {'url': 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=400', 'title': 'Fashion Item 2'},
      {'url': 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400', 'title': 'Fashion Item 3'},
      {'url': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400', 'title': 'Fashion Item 4'},
    ];

    final selectedData = categoryData[query.toLowerCase()] ?? defaultData;

    return List.generate(
      selectedData.length,
      (index) {
        final item = selectedData[index];
        return PinterestImage(
          id: 'mock_${query}_${index}_${DateTime.now().millisecondsSinceEpoch}',
          url: item['url']!,
          title: item['title']!,
          description: 'Beautiful ${item['title']!.toLowerCase()} perfect for any occasion',
          width: 400,
          height: 600,
          originalUrl: item['url']!,
        );
      },
    );
  }

  Future<List<String>> getPopularSearchTerms() async {
    // Return popular fashion search terms
    return [
      'saree',
      'jewelry',
      'dress',
      'lehenga',
      'kurta',
      'earrings',
      'necklace',
      'bridal wear',
      'traditional wear',
      'accessories'
    ];
  }
}
