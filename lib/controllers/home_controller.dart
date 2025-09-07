import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:fabisy/services/scrape_creators_pinterest_service.dart';

class HomeController extends GetxController {
  final ScrapeCreatorsPinterestService _pinterestService = 
      ScrapeCreatorsPinterestService();
  
  final RxMap<String, List<PinterestItem>> categorySamples = 
      <String, List<PinterestItem>>{}.obs;
  final RxList<PinterestItem> favorites = <PinterestItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  
  final List<String> categories = ['saree', 'jewelry', 'dresses', 'lehenga', 'shoes', 'accessories'];
  
  @override
  void onInit() {
    super.onInit();
    loadInitialContent();
    loadFavoritesFromStorage();
  }
  
  Future<void> loadInitialContent() async {
    isLoading.value = true;
    
    try {
      for (String category in categories) {
        final samples = await _pinterestService.searchByCategory(
          category, 
          limit: 4
        );
        categorySamples[category] = samples;
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Failed to load content: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> refreshContent() async {
    isRefreshing.value = true;
    
    try {
      // Refresh samples based on user favoriting patterns
      for (String category in categories) {
        final newSamples = await _pinterestService.searchByCategory(
          category, 
          limit: 4
        );
        categorySamples[category] = newSamples;
      }
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Failed to refresh content: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRefreshing.value = false;
    }
  }
  
  Future<void> refreshCategorySamples() async {
    // Refresh samples based on user favoriting patterns
    for (String category in categories) {
      final newSamples = await _pinterestService.searchByCategory(
        category, 
        limit: 4
      );
      categorySamples[category] = newSamples;
    }
  }
  
  void toggleFavorite(PinterestItem item) {
    if (item.isFavorited) {
      favorites.removeWhere((fav) => fav.id == item.id);
      item.isFavorited = false;
      
      // Update the item in category samples if it exists
      categorySamples.forEach((category, items) {
        for (var categoryItem in items) {
          if (categoryItem.id == item.id) {
            categoryItem.isFavorited = false;
          }
        }
      });
      
      Get.snackbar(
        'Removed from Favorites', 
        '${item.title} removed from your collection',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } else {
      favorites.add(item);
      item.isFavorited = true;
      
      // Update the item in category samples if it exists
      categorySamples.forEach((category, items) {
        for (var categoryItem in items) {
          if (categoryItem.id == item.id) {
            categoryItem.isFavorited = true;
          }
        }
      });
      
      Get.snackbar(
        'Added to Favorites', 
        '${item.title} added to your collection',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
    
    saveFavoritesToStorage();
    update();
  }
  
  void saveFavoritesToStorage() async {
    try {
      final box = await Hive.openBox('favorites');
      final favoritesJson = favorites.map((item) => item.toJson()).toList();
      await box.put('user_favorites', favoritesJson);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }
  
  void loadFavoritesFromStorage() async {
    try {
      final box = await Hive.openBox('favorites');
      final favoritesJson = box.get('user_favorites', defaultValue: []);
      
      if (favoritesJson is List) {
        favorites.value = favoritesJson
            .map((json) => PinterestItem.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        
        // Update favorited status in category samples
        _updateFavoritedStatusInSamples();
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }
  
  void _updateFavoritedStatusInSamples() {
    final favoriteIds = favorites.map((item) => item.id).toSet();
    
    categorySamples.forEach((category, items) {
      for (var item in items) {
        item.isFavorited = favoriteIds.contains(item.id);
      }
    });
    update();
  }
  
  bool isItemFavorited(String itemId) {
    return favorites.any((item) => item.id == itemId);
  }
  
  PinterestItem? getFavoriteById(String itemId) {
    try {
      return favorites.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }
  
  List<PinterestItem> getFavoritesByCategory(String category) {
    return favorites.where((item) => 
      item.category.toLowerCase() == category.toLowerCase()
    ).toList();
  }
  
  int get totalFavorites => favorites.length;
  
  Map<String, int> get favoritesByCategory {
    final Map<String, int> categoryCount = {};
    for (String category in categories) {
      categoryCount[category] = getFavoritesByCategory(category).length;
    }
    return categoryCount;
  }
  
  @override
  void onClose() {
    _pinterestService.dispose();
    super.onClose();
  }
}
