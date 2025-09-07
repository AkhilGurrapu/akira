import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:fabisy/screens/try_on_screen.dart';
import 'package:fabisy/models/catalog_item.dart';
import 'package:fabisy/services/gemini_service.dart';
import 'package:fabisy/controllers/home_controller.dart';
import 'package:fabisy/services/scrape_creators_pinterest_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UpdatedMobileHomeScreen extends StatefulWidget {
  const UpdatedMobileHomeScreen({super.key});

  @override
  State<UpdatedMobileHomeScreen> createState() => _UpdatedMobileHomeScreenState();
}

class _UpdatedMobileHomeScreenState extends State<UpdatedMobileHomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final GeminiService _geminiService = GeminiService();
  final HomeController _homeController = Get.put(HomeController());
  
  String _selectedSource = 'Upload';
  int _selectedTabIndex = 0;

  File? _uploadedImage;
  Uint8List? _generatedImageBytes;
  bool _isGenerating = false;

  final List<String> _sources = ['Camera', 'Upload'];
  final List<String> _tabs = ['Dresses', 'Jewelry', 'Favorites'];

  Future<void> _pickImage() async {
    final ImageSource source = _selectedSource == 'Camera' 
        ? ImageSource.camera 
        : ImageSource.gallery;
    
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null && mounted) {
      setState(() {
        _uploadedImage = File(pickedFile.path);
        _generatedImageBytes = null; // Reset any previous generated image
      });
    }
  }

  Future<void> _generateImageWithItem(CatalogItem item) async {
    if (_uploadedImage == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final responseBody = await _geminiService.sendRequest(
        _uploadedImage!, 
        item.imageAssetPath, 
        item.prompt
      );
      
      final responseJson = json.decode(responseBody);
      final candidates = responseJson['candidates'] as List;
      
      if (candidates.isNotEmpty) {
        final parts = candidates[0]['content']['parts'] as List;
        String? base64Image;
        
        for (var part in parts) {
          if (part['inlineData'] != null) {
            base64Image = part['inlineData']['data'];
            break;
          }
        }

        if (base64Image != null) {
          final imageBytes = base64Decode(base64Image);
          setState(() {
            _generatedImageBytes = imageBytes;
          });
        } else {
          _setError('No image found in the response.');
        }
      } else {
        _setError('No candidates found in the response.');
      }
    } catch (e) {
      _setError('Error: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _generateImageWithPinterestItem(PinterestItem item) async {
    if (_uploadedImage == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // Create a prompt for Pinterest item
      final prompt = '''
        Replace the person's current clothing with the exact fashion item shown in the second image. 
        Apply the item's design, colors, patterns, and style from the second image to the person in the first image. 
        Ensure the item fits naturally on the person's body posture and maintains realistic lighting and shadows that match the original photo.
        Category: ${item.category}
        Style: ${item.title}
      ''';
      
      final responseBody = await _geminiService.sendRequestWithUrl(
        _uploadedImage!, 
        item.imageUrl, 
        prompt
      );
      
      final responseJson = json.decode(responseBody);
      final candidates = responseJson['candidates'] as List;
      
      if (candidates.isNotEmpty) {
        final parts = candidates[0]['content']['parts'] as List;
        String? base64Image;
        
        for (var part in parts) {
          if (part['inlineData'] != null) {
            base64Image = part['inlineData']['data'];
            break;
          }
        }

        if (base64Image != null) {
          final imageBytes = base64Decode(base64Image);
          setState(() {
            _generatedImageBytes = imageBytes;
          });
        } else {
          _setError('No image found in the response.');
        }
      } else {
        _setError('No candidates found in the response.');
      }
    } catch (e) {
      _setError('Error: $e');
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  void _setError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _downloadGeneratedImage() async {
    if (_generatedImageBytes == null) return;

    try {
      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/fabisy_tryon_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(_generatedImageBytes!);
      await Share.shareXFiles([XFile(file.path)], text: 'Make Yourself Fabulous Result from fabisy');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image ready for download!'),
          backgroundColor: Color(0xFFEC1380),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _setError('Download failed: $e');
    }
  }

  void _startTryOn() {
    if (_uploadedImage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TryOnScreen(image: _uploadedImage!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Source Toggle
            _buildSourceToggle(),
            
            // Change Photo Button (always visible when image is uploaded)
            if (_uploadedImage != null) _buildChangePhotoButton(),
            
            // Main Image Area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildImageArea(),
                    _buildCatalogSection(),
                  ],
                ),
              ),
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
            'Make Yourself Fabulous',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181114),
            ),
          ),
          const Spacer(),
          // Show favorites count
          Obx(() => _homeController.totalFavorites > 0
              ? Container(
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
                        '${_homeController.totalFavorites}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEC1380),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildSourceToggle() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: _sources.map((source) {
          final isSelected = source == _selectedSource;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSource = source;
                });
              },
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    source,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFFEC1380) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChangePhotoButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _pickImage,
        icon: Icon(
          _selectedSource == 'Camera' ? Icons.camera_alt : Icons.upload_file,
          size: 20,
        ),
        label: Text(
          _selectedSource == 'Camera' ? 'Take New Photo' : 'Upload New Photo',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEC1380),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          DragTarget<Object>(
            onAcceptWithDetails: (details) {
              if (_uploadedImage != null) {
                if (details.data is CatalogItem) {
                  _generateImageWithItem(details.data as CatalogItem);
                } else if (details.data is PinterestItem) {
                  _generateImageWithPinterestItem(details.data as PinterestItem);
                }
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isDragOver = candidateData.isNotEmpty && _uploadedImage != null;
              
              return GestureDetector(
                onTap: _uploadedImage == null ? _pickImage : (_generatedImageBytes != null ? _downloadGeneratedImage : _startTryOn),
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width * 1.5, // 2:3 aspect ratio
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF3F4F6),
                    border: isDragOver ? Border.all(
                      color: const Color(0xFFEC1380),
                      width: 3,
                    ) : null,
                  ),
                  child: _uploadedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _generatedImageBytes != null
                                  ? Image.memory(
                                      _generatedImageBytes!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      _uploadedImage!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            
                            // Drag overlay hint
                            if (isDragOver)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFFEC1380).withOpacity(0.2),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        size: 48,
                                        color: Color(0xFFEC1380),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Drop here to try on',
                                        style: TextStyle(
                                          color: Color(0xFFEC1380),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            
                            // Download button (only show for generated images)
                            if (_generatedImageBytes != null)
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEC1380),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x40000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.download,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            
                            // Try on more button (only show for original uploaded images)
                            if (_generatedImageBytes == null)
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEC1380),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x40000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Try On More',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEC1380).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Color(0xFFEC1380),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedSource == 'Camera' ? 'Tap to capture' : 'Tap to upload',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF181114),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Choose a photo with good lighting',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
          
          // Loading indicator below image
          if (_isGenerating)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC1380)),
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Generating your Make Yourself Fabulous...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF181114),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCatalogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Catalog',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181114),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Tab selector
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
          ),
          child: Row(
            children: _tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final tab = entry.value;
              final isSelected = index == _selectedTabIndex;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? const Color(0xFFEC1380) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tab,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFFEC1380) : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Catalog grid
        _buildCatalogGrid(),
      ],
    );
  }

  Widget _buildCatalogGrid() {
    // Show loading state while fetching Pinterest samples
    return Obx(() {
      if (_homeController.isLoading.value) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: const Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC1380)),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading fashion items...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Show different content based on selected tab
      if (_selectedTabIndex == 0) {
        // Dresses tab - show local catalog + Pinterest samples
        return _buildDressesGrid();
      } else if (_selectedTabIndex == 1) {
        // Jewelry tab - show local catalog + Pinterest samples
        return _buildJewelryGrid();
      } else {
        // Favorites tab - show favorites from Pinterest
        return _buildFavoritesGrid();
      }
    });
  }

  Widget _buildDressesGrid() {
    final pinterestSamples = _homeController.categorySamples['dresses'] ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pinterest samples section only
          if (pinterestSamples.isNotEmpty) ...[
            const Text(
              'Indian Sarees',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF181114),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: pinterestSamples.length,
              itemBuilder: (context, index) {
                final item = pinterestSamples[index];
                return _buildPinterestItem(item);
              },
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Loading Indian Sarees...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJewelryGrid() {
    final pinterestSamples = _homeController.categorySamples['jewelry'] ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pinterest samples section only
          if (pinterestSamples.isNotEmpty) ...[
            const Text(
              'Indian Jewelry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF181114),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: pinterestSamples.length,
              itemBuilder: (context, index) {
                final item = pinterestSamples[index];
                return _buildPinterestItem(item);
              },
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Loading Indian Jewelry...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFavoritesGrid() {
    return Obx(() {
      if (_homeController.favorites.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: const Center(
            child: Column(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: Color(0xFF9CA3AF),
                ),
                SizedBox(height: 16),
                Text(
                  'No favorites yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Heart items in the catalog to see them here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: _homeController.favorites.length,
          itemBuilder: (context, index) {
            final item = _homeController.favorites[index];
            return _buildPinterestItem(item);
          },
        ),
      );
    });
  }

  Widget _buildPinterestItem(PinterestItem item) {
    final isEnabled = _uploadedImage != null && !_isGenerating;
    
    return Draggable<PinterestItem>(
      data: item,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC1380).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: item.thumbnailUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF3F4F6),
            border: Border.all(
              color: const Color(0xFFEC1380).withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.drag_indicator,
              color: Color(0xFFEC1380),
              size: 32,
            ),
          ),
        ),
      ),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Stack(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC1380)),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
              
              // Drag indicator (only show when image is uploaded and enabled)
              if (isEnabled)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC1380).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.drag_handle,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              
              // Heart Icon
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _homeController.toggleFavorite(item),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.isFavorited ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: item.isFavorited ? const Color(0xFFEC1380) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              
              // Try on button
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: ElevatedButton(
                  onPressed: isEnabled ? () => _generateImageWithPinterestItem(item) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC1380),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isEnabled ? 'Try On' : 'Upload Image First',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              // Status text overlay
              if (!isEnabled && _uploadedImage != null && _isGenerating)
                Positioned(
                  bottom: 50,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC1380).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Generating...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogItem(CatalogItem item) {
    final isEnabled = _uploadedImage != null && !_isGenerating;
    
    return Draggable<CatalogItem>(
      data: item,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC1380).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item.imageAssetPath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFF3F4F6),
            border: Border.all(
              color: const Color(0xFFEC1380).withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.drag_indicator,
              color: Color(0xFFEC1380),
              size: 32,
            ),
          ),
        ),
      ),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF3F4F6),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        item.imageAssetPath,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Color(0xFF9CA3AF),
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                    if (isEnabled)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC1380).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.drag_handle,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF181114),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isEnabled && _uploadedImage != null && _isGenerating)
              const Text(
                'Generating...',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEC1380),
                ),
              )
            else if (!isEnabled && _uploadedImage == null)
              const Text(
                'Upload image first',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
