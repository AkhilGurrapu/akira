import 'package:get/get.dart';
import 'package:fabisy/services/scrape_creators_pinterest_service.dart';
import 'package:fabisy/controllers/home_controller.dart';

class PinterestSearchController extends GetxController {
  final ScrapeCreatorsPinterestService _pinterestService = 
      ScrapeCreatorsPinterestService();
  
  final RxList<PinterestItem> searchResults = <PinterestItem>[].obs;
  final RxBool isSearching = false.obs;
  final RxString selectedCategory = 'all'.obs;
  final RxString currentQuery = ''.obs;
  final RxList<String> searchHistory = <String>[].obs;
  final RxList<String> popularTerms = <String>[].obs;
  
  final RxList<String> categories = <String>['all', 'saree', 'jewelry', 'dresses', 'lehenga', 'shoes', 'accessories'].obs;
  
  // Get HomeController instance to sync favorites
  HomeController get _homeController => Get.find<HomeController>();
  
  @override
  void onInit() {
    super.onInit();
    loadPopularTerms();
    loadSearchHistory();
  }
  
  Future<void> loadPopularTerms() async {
    popularTerms.value = CategorySearchGenerator.getAllCategories();
  }
  
  void loadSearchHistory() {
    // Load from local storage if needed
    // For now, using sample history
    searchHistory.value = [
      'elegant saree',
      'gold jewelry',
      'party dress',
      'bridal lehenga'
    ];
  }
  
  Future<void> searchImages(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    
    currentQuery.value = query.trim();
    isSearching.value = true;
    searchResults.clear();
    
    // Add to search history
    if (!searchHistory.contains(query)) {
      searchHistory.insert(0, query);
      if (searchHistory.length > 10) {
        searchHistory.removeRange(10, searchHistory.length);
      }
    }
    
    try {
      List<PinterestItem> results = [];
      
      if (selectedCategory.value == 'all') {
        // Search across all categories
        for (String category in CategorySearchGenerator.getAllCategories()) {
          final categoryResults = await _pinterestService.searchByCategory(
            category, 
            limit: 8
          );
          results.addAll(categoryResults);
        }
      } else {
        // Search specific category
        results = await _pinterestService.searchByQuery(
          '${selectedCategory.value} $query',
          limit: 30
        );
      }
      
      // Filter results based on query and update favorited status
      searchResults.value = results.where((item) =>
          item.title.toLowerCase().contains(query.toLowerCase()) ||
          item.description.toLowerCase().contains(query.toLowerCase()) ||
          item.category.toLowerCase().contains(query.toLowerCase())
      ).map((item) {
        // Sync with favorites from HomeController
        item.isFavorited = _homeController.isItemFavorited(item.id);
        return item;
      }).toList();
      
      // Shuffle results for variety
      searchResults.shuffle();
      
    } catch (e) {
      Get.snackbar(
        'Search Error', 
        'Failed to search: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSearching.value = false;
    }
  }
  
  Future<void> searchByCategory(String category) async {
    selectedCategory.value = category;
    
    if (category == 'all') {
      if (currentQuery.value.isNotEmpty) {
        await searchImages(currentQuery.value);
      } else {
        await loadTrendingImages();
      }
    } else {
      isSearching.value = true;
      searchResults.clear();
      
      try {
        final results = await _pinterestService.searchByCategory(
          category,
          limit: 30
        );
        
        searchResults.value = results.map((item) {
          item.isFavorited = _homeController.isItemFavorited(item.id);
          return item;
        }).toList();
        
        currentQuery.value = category;
        
      } catch (e) {
        Get.snackbar(
          'Search Error', 
          'Failed to load $category items: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        isSearching.value = false;
      }
    }
  }
  
  Future<void> loadTrendingImages() async {
    isSearching.value = true;
    searchResults.clear();
    
    try {
      List<PinterestItem> trendingItems = [];
      
      // Load trending items from each category
      for (String category in CategorySearchGenerator.getAllCategories().take(4)) {
        final categoryItems = await _pinterestService.searchByCategory(
          category,
          limit: 6
        );
        trendingItems.addAll(categoryItems);
      }
      
      trendingItems.shuffle();
      searchResults.value = trendingItems.take(24).map((item) {
        item.isFavorited = _homeController.isItemFavorited(item.id);
        return item;
      }).toList();
      
      currentQuery.value = 'Trending';
      
    } catch (e) {
      Get.snackbar(
        'Error', 
        'Failed to load trending items: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSearching.value = false;
    }
  }
  
  void toggleFavorite(PinterestItem item) {
    // Use HomeController's toggle favorite method to maintain sync
    _homeController.toggleFavorite(item);
    
    // Update the item in search results
    final index = searchResults.indexWhere((result) => result.id == item.id);
    if (index != -1) {
      searchResults[index].isFavorited = item.isFavorited;
      searchResults.refresh();
    }
  }
  
  void clearSearch() {
    searchResults.clear();
    currentQuery.value = '';
    selectedCategory.value = 'all';
  }
  
  void clearSearchHistory() {
    searchHistory.clear();
  }
  
  List<PinterestItem> getResultsByCategory(String category) {
    return searchResults.where((item) => 
      item.category.toLowerCase() == category.toLowerCase()
    ).toList();
  }
  
  bool get hasResults => searchResults.isNotEmpty;
  bool get isSearchActive => currentQuery.value.isNotEmpty;
  
  @override
  void onClose() {
    _pinterestService.dispose();
    super.onClose();
  }
}
