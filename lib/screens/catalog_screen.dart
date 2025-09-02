import 'package:flutter/material.dart';
import 'package:akira/services/pinterest_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final PinterestService _pinterestService = PinterestService();
  final TextEditingController _searchController = TextEditingController();
  
  List<PinterestImage> _images = [];
  List<String> _popularTerms = [];
  List<String> _savedImageIds = [];
  bool _isLoading = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSavedImages();
    _loadPopularTerms();
    _searchImages('saree'); // Default search
  }

  Future<void> _loadSavedImages() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList('saved_pinterest_images') ?? [];
    setState(() {
      _savedImageIds = savedIds;
    });
  }

  Future<void> _loadPopularTerms() async {
    try {
      final terms = await _pinterestService.getPopularSearchTerms();
      setState(() {
        _popularTerms = terms;
      });
    } catch (e) {
      print('Error loading popular terms: $e');
    }
  }

  Future<void> _searchImages(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentQuery = query;
    });

    try {
      final images = await _pinterestService.searchImages(query);
      setState(() {
        _images = images.map((image) {
          image.isSaved = _savedImageIds.contains(image.id);
          return image;
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSaveImage(PinterestImage image) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      image.isSaved = !image.isSaved;
      if (image.isSaved) {
        _savedImageIds.add(image.id);
      } else {
        _savedImageIds.remove(image.id);
      }
    });

    // Save to local storage
    await prefs.setStringList('saved_pinterest_images', _savedImageIds);
    
    // Save image details for home screen
    final savedImages = prefs.getStringList('saved_image_details') ?? [];
    if (image.isSaved) {
      savedImages.add(json.encode(image.toJson()));
    } else {
      savedImages.removeWhere((imageJson) {
        final imageData = json.decode(imageJson);
        return imageData['id'] == image.id;
      });
    }
    await prefs.setStringList('saved_image_details', savedImages);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          image.isSaved ? 'Image saved to collection' : 'Image removed from collection',
        ),
        backgroundColor: const Color(0xFFEC1380),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            if (_popularTerms.isNotEmpty) _buildPopularTerms(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC1380)),
                      ),
                    )
                  : _buildImageGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
      ),
      child: Row(
        children: [
          const Text(
            'Catalog',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181114),
            ),
          ),
          const Spacer(),
          if (_savedImageIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEC1380).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite,
                    size: 16, 
                    color: Color(0xFFEC1380),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_savedImageIds.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEC1380),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for fashion items...',
          hintStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF6B7280),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.clear,
                    color: Color(0xFF6B7280),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: _searchImages,
        onChanged: (value) {
          setState(() {}); // Update UI for clear button
        },
      ),
    );
  }

  Widget _buildPopularTerms() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _popularTerms.length,
        itemBuilder: (context, index) {
          final term = _popularTerms[index];
          final isSelected = term.toLowerCase() == _currentQuery.toLowerCase();
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                _searchController.text = term;
                _searchImages(term);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEC1380) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    term,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageGrid() {
    if (_images.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 16),
            Text(
              'No images found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        return _buildImageCard(image);
      },
    );
  }

  Widget _buildImageCard(PinterestImage image) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF3F4F6),
      ),
      child: Stack(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              image.url,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: const Color(0xFFF3F4F6),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC1380)),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Color(0xFF9CA3AF),
                  ),
                );
              },
            ),
          ),
          
          // Save button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _toggleSaveImage(image),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  image.isSaved ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                  color: image.isSaved ? const Color(0xFFEC1380) : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          
          // Title overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Text(
                image.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
