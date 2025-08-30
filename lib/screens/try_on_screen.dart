import 'dart:convert';
import 'dart:io';

import 'package:akira/services/gemini_service.dart';
import 'package:akira/models/catalog_item.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:akira/widgets/side_panel.dart';
import 'package:flutter/material.dart';

class TryOnScreen extends StatefulWidget {
  final File image;

  const TryOnScreen({super.key, required this.image});

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
    return Scaffold(
      backgroundColor: const Color(0xFF1E272E),
      appBar: AppBar(
        title: const Text('Try-On'),
        backgroundColor: const Color(0xFF2C3A47),
        actions: [
          DropdownButton<String>(
            value: _selectedPrompt,
            onChanged: (String? newValue) {
              setState(() {
                _selectedPrompt = newValue!;
              });
            },
            items: _samplePrompts.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(color: Colors.black)),
              );
            }).toList(),
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.white),
            iconEnabledColor: Colors.white,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: DragTarget<CatalogItem>(
              onAcceptWithDetails: (details) {
                // Convert global offset to local within the drop area
                final renderObject = _dropAreaKey.currentContext?.findRenderObject();
                if (renderObject is RenderBox) {
                  final local = renderObject.globalToLocal(details.offset);
                  _generateImage(details.data, local);
                } else {
                  _generateImage(details.data, details.offset);
                }
              },
              builder: (context, candidateData, rejectedData) {
                return RepaintBoundary(
                  key: _repaintKey,
                  child: Stack(
                    key: _dropAreaKey,
                    alignment: Alignment.center,
                    children: [
                      Center(child: Image.file(widget.image)),
                      ..._overlays.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return Positioned(
                          left: item.position.dx,
                          top: item.position.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              final size = _getDropAreaSize();
                              final next = item.position + details.delta;
                              setState(() {
                                _overlays[i] = item.copyWith(
                                  position: _clampToBounds(next, item.size, size),
                                );
                              });
                            },
                            onLongPress: () {
                              setState(() {
                                _overlays.removeAt(i);
                              });
                            },
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Image.memory(item.bytes, width: item.size.width, height: item.size.height),
                                Container(
                                  margin: const EdgeInsets.only(top: 2, right: 2),
                                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.drag_indicator, size: 16, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (_isLoading) const CircularProgressIndicator(),
                    ],
                  ),
                );
              },
            ),
          ),
          const SidePanel(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportComposition,
        icon: const Icon(Icons.download),
        label: const Text('Download'),
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
      ),
      bottomSheet: _error.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.withOpacity(0.8),
              child: Text(
                _error,
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
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
      await Share.shareXFiles([XFile(file.path)], text: 'Virtual Try-On result');
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
