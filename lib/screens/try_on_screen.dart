import 'dart:convert';
import 'dart:io';

import 'package:fabisy/services/gemini_service.dart';
import 'package:fabisy/models/catalog_item.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fabisy/widgets/side_panel.dart';
import 'package:flutter/material.dart';

class TryOnScreen extends StatefulWidget {
  final File image;
  final dynamic preselectedItem; // Can be CatalogItem or PinterestItem

  const TryOnScreen({super.key, required this.image, this.preselectedItem});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  final GeminiService _geminiService = GeminiService();
  final List<_OverlayItem> _overlays = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedPrompt = 'Place this item on the person in the image.';
  final GlobalKey _dropAreaKey = GlobalKey();
  final GlobalKey _repaintKey = GlobalKey();

  final List<String> _samplePrompts = [
    'Place this item on the person in the image.',
    'Make the person wear this item.',
    'Generate a new image with the person wearing this.',
    'Create a realistic image of the person with this item on.',
  ];

  Future<void> _generateImage(CatalogItem item, Offset localDropOffset) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final responseBody = await _geminiService.sendRequest(
          widget.image, item.imageAssetPath, item.prompt);
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
          final size = _getDropAreaSize();
          final desired = Offset(localDropOffset.dx - 75, localDropOffset.dy - 75);
          final clamped = _clampToBounds(desired, const Size(150, 150), size);
          setState(() {
            _overlays.add(_OverlayItem(bytes: imageBytes, position: clamped, size: const Size(150, 150)));
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
        _isLoading = false;
      });
    }
  }

  void _setError(String message) {
    setState(() {
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 800;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 20,
              color: Color(0xFF181114),
            ),
          ),
        ),
        title: const Text(
          'Make Yourself Fabulous',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF181114),
          ),
        ),
        centerTitle: true,
        actions: [
          if (_overlays.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  _overlays.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All overlays cleared'),
                    backgroundColor: const Color(0xFFEC1380),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.clear_all, color: Color(0xFF181114)),
              tooltip: 'Clear all overlays',
            ),
          IconButton(
            onPressed: _exportComposition,
            icon: const Icon(Icons.download, color: Color(0xFF181114)),
            tooltip: 'Download image',
          ),
        ],
      ),
      body: Column(
        children: [
          if (isSmallScreen) _buildMobilePromptSelector(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF334155),
                        width: 1,
                      ),
                    ),
                    child: DragTarget<CatalogItem>(
                      onAcceptWithDetails: (details) {
                        final renderObject = _dropAreaKey.currentContext?.findRenderObject();
                        if (renderObject is RenderBox) {
                          final local = renderObject.globalToLocal(details.offset);
                          _generateImage(details.data, local);
                        } else {
                          _generateImage(details.data, details.offset);
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isDragOver = candidateData.isNotEmpty;
                        
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDragOver 
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF334155),
                              width: isDragOver ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: RepaintBoundary(
                              key: _repaintKey,
                              child: Stack(
                                key: _dropAreaKey,
                                fit: StackFit.expand,
                                children: [
                                  // Background image with proper sizing
                                  Center(
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth: size.width * 0.8,
                                        maxHeight: size.height * 0.8,
                                      ),
                                      child: Image.file(
                                        widget.image,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  
                                  // Drag hint overlay
                                  if (candidateData.isNotEmpty)
                                    Container(
                                      color: const Color(0xFF6366F1).withOpacity(0.1),
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
                                  
                                  // Overlays
                                  ..._overlays.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final item = entry.value;
                                    return Positioned(
                                      left: item.position.dx,
                                      top: item.position.dy,
                                      child: _buildOverlayItem(item, i),
                                    );
                                  }),
                                  
                                  // Loading indicator
                                  if (_isLoading)
                                    Container(
                                      color: Colors.black.withOpacity(0.3),
                                      child: const Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                                                        CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFEC1380),
                              ),
                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              'Generating your Make Yourself Fabulous...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  
                                  // Empty state
                                  if (_overlays.isEmpty && !_isLoading)
                                    Positioned(
                                      bottom: 20,
                                      left: 20,
                                      right: 20,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A).withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFF334155),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Color(0xFF6366F1),
                                              size: 20,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Drag items from the catalog to see how they look on you',
                                                style: TextStyle(
                                                  color: Color(0xFFCBD5E1),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (!isSmallScreen) const SidePanel(hasImage: true),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _error.isNotEmpty ? _buildErrorSheet() : null,
      floatingActionButton: _overlays.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _exportComposition,
              icon: const Icon(Icons.download),
              label: const Text('Export'),
              backgroundColor: const Color(0xFFEC1380),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildOverlayItem(_OverlayItem item, int index) {
    return GestureDetector(
      onPanUpdate: (details) {
        final size = _getDropAreaSize();
        final next = item.position + details.delta;
        setState(() {
          _overlays[index] = item.copyWith(
            position: _clampToBounds(next, item.size, size),
          );
        });
      },
      onLongPress: () {
        setState(() {
          _overlays.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Overlay removed'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                item.bytes,
                width: item.size.width,
                height: item.size.height,
                fit: BoxFit.cover,
              ),
            ),
            // Control buttons
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.drag_indicator,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () async {
                      // Export this specific overlay
                      await _exportSingleOverlay(item.bytes);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.download,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSelector() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: DropdownButton<String>(
        value: _selectedPrompt,
        onChanged: (String? newValue) {
          setState(() {
            _selectedPrompt = newValue!;
          });
        },
        items: _samplePrompts.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value.length > 30 ? '${value.substring(0, 30)}...' : value,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        isExpanded: true,
        underline: Container(),
        icon: const Icon(Icons.expand_more, size: 20),
      ),
    );
  }

  Widget _buildMobilePromptSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: DropdownButton<String>(
        value: _selectedPrompt,
        onChanged: (String? newValue) {
          setState(() {
            _selectedPrompt = newValue!;
          });
        },
        items: _samplePrompts.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          );
        }).toList(),
        isExpanded: true,
        underline: Container(),
        dropdownColor: const Color(0xFF1E293B),
        icon: const Icon(Icons.expand_more, color: Colors.white),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildErrorSheet() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFDC2626),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _error = '';
                });
              },
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Size _getDropAreaSize() {
    final rb = _dropAreaKey.currentContext?.findRenderObject() as RenderBox?;
    return rb?.size ?? const Size(0, 0);
  }

  Offset _clampToBounds(Offset pos, Size childSize, Size container) {
    final maxX = (container.width - childSize.width).clamp(0, double.infinity);
    final maxY = (container.height - childSize.height).clamp(0, double.infinity);
    final dx = pos.dx.clamp(0, maxX as num).toDouble();
    final dy = pos.dy.clamp(0, maxY as num).toDouble();
    return Offset(dx, dy);
  }

  Future<void> _exportComposition() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/try_on_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Make Yourself Fabulous result');
    } catch (e) {
      _setError('Export failed: $e');
    }
  }

  Future<void> _exportSingleOverlay(Uint8List imageBytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/overlay_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(imageBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Generated overlay');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Overlay exported successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      _setError('Export failed: $e');
    }
  }
}

class _OverlayItem {
  final Uint8List bytes;
  final Offset position;
  final Size size;
  _OverlayItem({required this.bytes, required this.position, required this.size});
  _OverlayItem copyWith({Uint8List? bytes, Offset? position, Size? size}) =>
      _OverlayItem(bytes: bytes ?? this.bytes, position: position ?? this.position, size: size ?? this.size);
}
