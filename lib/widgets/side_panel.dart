import 'package:flutter/material.dart';
import 'package:akira/models/catalog_item.dart';

class SidePanel extends StatefulWidget {
  const SidePanel({super.key});

  @override
  State<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<SidePanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<CatalogItem> _dresses = dressCatalog;
  final List<CatalogItem> _jewelry = jewelryCatalog;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: const Color(0xFF2C3A47),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.yellow,
            labelColor: Colors.yellow,
            unselectedLabelColor: Colors.white,
            tabs: const [
              Tab(text: 'Dresses'),
              Tab(text: 'Jewelry'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemGrid(_dresses),
                _buildItemGrid(_jewelry),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(List<CatalogItem> items) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Draggable<CatalogItem>(
          data: item,
          feedback: Image.asset(item.imageAssetPath, width: 100, height: 100),
          childWhenDragging: Container(
            color: Colors.grey.withOpacity(0.5),
          ),
          child: Column(
            children: [
              Expanded(child: Image.asset(item.imageAssetPath)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  item.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
