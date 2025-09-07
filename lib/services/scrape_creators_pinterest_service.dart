import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ScrapeCreatorsConfig {
  static const String API_BASE = 'https://api.scrapecreators.com/v1/pinterest';
  static String get API_KEY => dotenv.env['SCRAPE_CREATORS_API_KEY'] ?? '';
  
  static Map<String, String> get headers => {
    'x-api-key': API_KEY,
    'Content-Type': 'application/json'
  };
}

class CategorySearchGenerator {
  static final Map<String, List<String>> searchTerms = {
    'dresses': [
      'indian saree mannequin display',
      'traditional indian saree model',
      'silk saree on mannequin',
      'designer indian saree display',
      'bridal saree mannequin fashion',
      'banarasi saree on model',
      'indian ethnic wear saree',
      'traditional saree draping style'
    ],
    'jewelry': [
      'indian gold jewelry set',
      'traditional kundan jewelry',
      'indian bridal jewelry gold',
      'diamond indian jewelry',
      'temple jewelry traditional',
      'indian necklace earrings set',
      'antique indian jewelry',
      'heavy indian gold jewelry'
    ],
    'shoes': [
      'high heel fashion shoes',
      'casual sneakers style',
      'boots fashion outfit',
      'sandals summer style',
      'formal dress shoes',
      'athletic shoes fashion',
      'ankle boots style',
      'platform shoes fashion'
    ],
    'accessories': [
      'handbags fashion style',
      'sunglasses fashion',
      'scarves fashion accessory',
      'watches fashion jewelry',
      'belts fashion style',
      'hats fashion accessory',
      'bags luxury fashion',
      'fashion accessories style'
    ],
    'saree': [
      'indian saree mannequin display',
      'traditional silk saree model',
      'banarasi saree on mannequin',
      'designer indian saree fashion',
      'bridal saree mannequin style',
      'kanchipuram saree display',
      'handloom saree on model',
      'ethnic indian saree draping'
    ],
    'lehenga': [
      'bridal lehenga choli',
      'designer party lehenga',
      'traditional wedding lehenga',
      'festive silk lehenga',
      'modern fusion lehenga',
      'royal embroidered lehenga',
      'elegant reception lehenga',
      'classic bridal lehenga'
    ]
  };
  
  static String getRandomSearchTerm(String category) {
    final terms = searchTerms[category.toLowerCase()] ?? ['fashion $category'];
    return terms[Random().nextInt(terms.length)];
  }
  
  static List<String> getAllCategories() {
    return searchTerms.keys.toList();
  }
}

class PinterestItem {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String thumbnailUrl;
  final String sourceUrl;
  final String category;
  final int width;
  final int height;
  final String boardName;
  final String pinnerName;
  bool isFavorited;
  final DateTime fetchedAt;
  
  PinterestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.sourceUrl,
    required this.category,
    required this.width,
    required this.height,
    required this.boardName,
    required this.pinnerName,
    this.isFavorited = false,
    required this.fetchedAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'thumbnailUrl': thumbnailUrl,
    'sourceUrl': sourceUrl,
    'category': category,
    'width': width,
    'height': height,
    'boardName': boardName,
    'pinnerName': pinnerName,
    'isFavorited': isFavorited,
    'fetchedAt': fetchedAt.toIso8601String(),
  };
  
  factory PinterestItem.fromJson(Map<String, dynamic> json) => PinterestItem(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    imageUrl: json['imageUrl'],
    thumbnailUrl: json['thumbnailUrl'],
    sourceUrl: json['sourceUrl'],
    category: json['category'],
    width: json['width'],
    height: json['height'],
    boardName: json['boardName'],
    pinnerName: json['pinnerName'],
    isFavorited: json['isFavorited'] ?? false,
    fetchedAt: DateTime.parse(json['fetchedAt']),
  );
  
  String generateTryOnPrompt() => '''
    Fashion item for Make Yourself Fabulous:
    - Category: $category
    - Style: $title
    - Description: $description
    - Original source: $sourceUrl
  ''';
}

class ScrapeCreatorsPinterestService {
  final http.Client _client = http.Client();
  
  // For development - use mock data if API key is not configured
  bool get _shouldUseMockData {
    return ScrapeCreatorsConfig.API_KEY.isEmpty || 
           ScrapeCreatorsConfig.API_KEY == 'your-scrape-creators-api-key';
  }
  
  Future<List<PinterestItem>> searchByCategory(String category, {int limit = 20}) async {
    if (_shouldUseMockData) {
      print('Using mock data - configure SCRAPE_CREATORS_API_KEY in .env file');
      return _getMockPinterestData(category, limit);
    }
    
    final searchQuery = CategorySearchGenerator.getRandomSearchTerm(category);
    
    try {
      final response = await _client.get(
        Uri.parse('${ScrapeCreatorsConfig.API_BASE}/search')
            .replace(queryParameters: {
          'query': searchQuery,
          'limit': limit.toString(),
        }),
        headers: ScrapeCreatorsConfig.headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parsePinterestResponse(data['pins'] ?? data['data'] ?? [], category);
      } else {
        print('Scrape Creators API Error: ${response.statusCode}');
        return _getMockPinterestData(category, limit);
      }
    } catch (e) {
      print('Search failed: $e');
      return _getMockPinterestData(category, limit);
    }
  }
  
  Future<List<PinterestItem>> searchByQuery(String query, {int limit = 30}) async {
    if (_shouldUseMockData) {
      print('Using mock data - configure SCRAPE_CREATORS_API_KEY in .env file');
      return _getMockPinterestData(query, limit);
    }
    
    try {
      final response = await _client.get(
        Uri.parse('${ScrapeCreatorsConfig.API_BASE}/search')
            .replace(queryParameters: {
          'query': query,
          'limit': limit.toString(),
        }),
        headers: ScrapeCreatorsConfig.headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parsePinterestResponse(data['pins'] ?? data['data'] ?? [], _categorizeQuery(query));
      } else {
        print('Scrape Creators API Error: ${response.statusCode}');
        return _getMockPinterestData(query, limit);
      }
    } catch (e) {
      print('Search failed: $e');
      return _getMockPinterestData(query, limit);
    }
  }
  
  List<PinterestItem> _parsePinterestResponse(List pins, String category) {
    return pins.map<PinterestItem>((pin) => PinterestItem(
      id: pin['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: pin['title'] ?? _generateFashionTitle(category),
      description: pin['description'] ?? 'Beautiful $category style perfect for any occasion',
      imageUrl: pin['images']?['orig']?['url'] ?? pin['image_url'] ?? '',
      thumbnailUrl: pin['images']?['237x']?['url'] ?? pin['images']?['orig']?['url'] ?? pin['image_url'] ?? '',
      sourceUrl: pin['link'] ?? pin['pin_url'] ?? '',
      category: category,
      width: pin['images']?['orig']?['width'] ?? pin['width'] ?? 564,
      height: pin['images']?['orig']?['height'] ?? pin['height'] ?? 564,
      boardName: pin['board']?['name'] ?? 'Fashion Board',
      pinnerName: pin['pinner']?['username'] ?? 'Fashion Lover',
      isFavorited: false,
      fetchedAt: DateTime.now(),
    )).where((item) => item.imageUrl.isNotEmpty).toList();
  }
  
  Future<PinterestItem?> getPinDetails(String pinId) async {
    if (_shouldUseMockData) {
      return null;
    }
    
    try {
      final response = await _client.get(
        Uri.parse('${ScrapeCreatorsConfig.API_BASE}/pin')
            .replace(queryParameters: {'id': pinId}),
        headers: ScrapeCreatorsConfig.headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pins = _parsePinterestResponse([data['pin'] ?? data], 'unknown');
        return pins.isNotEmpty ? pins.first : null;
      }
    } catch (e) {
      print('Error fetching pin details: $e');
    }
    return null;
  }
  
  String _categorizeQuery(String query) {
    final queryLower = query.toLowerCase();
    for (String category in CategorySearchGenerator.getAllCategories()) {
      if (queryLower.contains(category)) {
        return category;
      }
    }
    return 'fashion';
  }
  
  String _generateFashionTitle(String category) {
    final hash = DateTime.now().millisecondsSinceEpoch.hashCode.abs();
    final Map<String, List<String>> titleTemplates = {
      'dresses': [
        'Designer Evening Dress',
        'Casual Summer Dress',
        'Party Cocktail Dress',
        'Formal Office Dress',
        'Wedding Guest Dress',
        'Vintage Style Dress',
        'Modern Chic Dress',
        'Elegant Maxi Dress'
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
    
    List<String> templates = titleTemplates[category.toLowerCase()] ?? [
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
  
  // Mock data for development
  List<PinterestItem> _getMockPinterestData(String category, int limit) {
    final Map<String, List<Map<String, dynamic>>> categoryData = {
      'dresses': [
        {'url': 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400', 'title': 'Designer Evening Dress'},
        {'url': 'https://images.unsplash.com/photo-1539008835657-9e8e9680c956?w=400', 'title': 'Casual Summer Dress'},
        {'url': 'https://images.unsplash.com/photo-1566479179817-c0678c5ce26c?w=400', 'title': 'Party Cocktail Dress'},
        {'url': 'https://images.unsplash.com/photo-1516575150278-77136aed6920?w=400', 'title': 'Formal Office Dress'},
      ],
      'jewelry': [
        {'url': 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=400', 'title': 'Statement Gold Necklace'},
        {'url': 'https://images.unsplash.com/photo-1602173574767-37ac01994b2a?w=400', 'title': 'Diamond Earring Set'},
        {'url': 'https://images.unsplash.com/photo-1506630448388-4e683c67ddb0?w=400', 'title': 'Traditional Kundan Jewelry'},
        {'url': 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?w=400', 'title': 'Bridal Jewelry Collection'},
      ],
      'saree': [
        {'url': 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=400', 'title': 'Elegant Red Silk Saree'},
        {'url': 'https://images.unsplash.com/photo-1594736797933-d0b71ee5e632?w=400', 'title': 'Traditional Pink Cotton Saree'},
        {'url': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400', 'title': 'Blue Designer Saree'},
        {'url': 'https://images.unsplash.com/photo-1598300042247-d088f8ab3a91?w=400', 'title': 'Golden Bridal Saree'},
        {'url': 'https://images.unsplash.com/photo-1574146042765-e95a5b3e8a1e?w=400', 'title': 'Green Banarasi Saree'},
        {'url': 'https://images.unsplash.com/photo-1617019114583-affb34d1b3cd?w=400', 'title': 'Purple Wedding Saree'},
      ],
      'lehenga': [
        {'url': 'https://images.unsplash.com/photo-1587831990711-23ca6441447b?w=400', 'title': 'Bridal Lehenga Choli'},
        {'url': 'https://images.unsplash.com/photo-1562788869-4ed32648eb72?w=400', 'title': 'Designer Party Lehenga'},
        {'url': 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400', 'title': 'Traditional Wedding Lehenga'},
        {'url': 'https://images.unsplash.com/photo-1594736797933-d0b71ee5e632?w=400', 'title': 'Festive Silk Lehenga'},
      ],
      'shoes': [
        {'url': 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400', 'title': 'High Heel Fashion Shoes'},
        {'url': 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400', 'title': 'Casual Sneakers Style'},
        {'url': 'https://images.unsplash.com/photo-1544966503-7cc5ac882d5f?w=400', 'title': 'Boots Fashion Outfit'},
        {'url': 'https://images.unsplash.com/photo-1515347619252-60a4bf4fff4f?w=400', 'title': 'Sandals Summer Style'},
      ],
      'accessories': [
        {'url': 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400', 'title': 'Handbags Fashion Style'},
        {'url': 'https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=400', 'title': 'Sunglasses Fashion'},
        {'url': 'https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=400', 'title': 'Scarves Fashion Accessory'},
        {'url': 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=400', 'title': 'Watches Fashion Jewelry'},
      ]
    };

    final selectedData = categoryData[category.toLowerCase()] ?? categoryData['dresses']!;
    final shuffledData = List.from(selectedData)..shuffle();
    
    return List.generate(
      limit.clamp(1, shuffledData.length),
      (index) {
        final item = shuffledData[index % shuffledData.length];
        return PinterestItem(
          id: 'mock_${category}_${index}_${DateTime.now().millisecondsSinceEpoch}',
          title: item['title']!,
          description: 'Beautiful ${item['title']!.toLowerCase()} perfect for any occasion',
          imageUrl: item['url']!,
          thumbnailUrl: item['url']!,
          sourceUrl: item['url']!,
          category: category,
          width: 400,
          height: 600,
          boardName: 'Fashion Board',
          pinnerName: 'Fashion Lover',
          isFavorited: false,
          fetchedAt: DateTime.now(),
        );
      },
    );
  }
  
  void dispose() {
    _client.close();
  }
}

class APIErrorHandler {
  static void handleError(dynamic error) {
    if (error is http.Response) {
      switch (error.statusCode) {
        case 401:
          print('Auth Error: Invalid API key');
          break;
        case 429:
          print('Rate Limited: Too many requests. Please wait.');
          break;
        case 500:
          print('Server Error: Pinterest service unavailable');
          break;
        default:
          print('Error: Request failed: ${error.statusCode}');
      }
    } else {
      print('Network Error: Check your internet connection');
    }
  }
}
