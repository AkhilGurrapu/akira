class CatalogItem {
  final String id;
  final String name;
  final String imageAssetPath;
  final String prompt;

  const CatalogItem({
    required this.id,
    required this.name,
    required this.imageAssetPath,
    required this.prompt,
  });
}

const List<CatalogItem> dressCatalog = [
  CatalogItem(
    id: 'd1',
    name: 'Crimson Saree',
    imageAssetPath: 'assets/images/saree/saree1.jpg',
    prompt:
        "Drape the person in an elegant, traditional crimson red Banarasi silk saree with intricate gold zari work. Ensure the drape is natural and fits the person's posture.",
  ),
  CatalogItem(
    id: 'd2',
    name: 'Royal Blue Lehenga',
    imageAssetPath: 'assets/images/saree/saree2.jpg',
    prompt:
        'Dress the person in a stunning royal blue lehenga choli with heavy silver embroidery. The outfit should look grand and opulent.',
  ),
  CatalogItem(
    id: 'd3',
    name: 'Golden Anarkali',
    imageAssetPath: 'assets/images/saree/saree3.jpg',
    prompt:
        "Change the person's attire to a floor-length golden Anarkali suit with delicate mirror work. The silhouette should be flowing and graceful.",
  ),
  CatalogItem(
    id: 'd4',
    name: 'Emerald Green Sharara',
    imageAssetPath: 'assets/images/saree/saree4.jpg',
    prompt:
        'Outfit the person in a modern yet traditional emerald green sharara suit with a short kurti, decorated with pearl embellishments.',
  ),
  CatalogItem(
    id: 'd5',
    name: 'Pastel Pink Saree',
    imageAssetPath: 'assets/images/saree/saree5.jpg',
    prompt:
        'Drape the person in a delicate pastel pink georgette saree with a simple, elegant silver border, suitable for a daytime event.',
  ),
];

const List<CatalogItem> jewelryCatalog = [
  CatalogItem(
    id: 'j1',
    name: 'Temple Necklace',
    imageAssetPath: 'assets/images/jewelry/j1.jpg',
    prompt:
        "Adorn the person's neck with a heavy, ornate South Indian temple jewelry gold necklace featuring intricate carvings of deities.",
  ),
  CatalogItem(
    id: 'j2',
    name: 'Kundan Choker',
    imageAssetPath: 'assets/images/jewelry/j2.jpg',
    prompt:
        'Place a radiant Kundan choker necklace with uncut diamonds and green gemstones snugly around the person\'s neck.',
  ),
  CatalogItem(
    id: 'j3',
    name: 'Chandbali Earrings',
    imageAssetPath: 'assets/images/jewelry/j3.jpg',
    prompt:
        "Add a pair of large, crescent-shaped Chandbali earrings made of gold and pearls to the person's ears.",
  ),
  CatalogItem(
    id: 'j4',
    name: 'Maang Tikka',
    imageAssetPath: 'assets/images/jewelry/j4.jpg',
    prompt:
        "Place a beautiful Polki and pearl maang tikka on the person's forehead, parting their hair in the center.",
  ),
  CatalogItem(
    id: 'j5',
    name: 'Diamond Set',
    imageAssetPath: 'assets/images/jewelry/j5.jpg',
    prompt:
        'Adorn the person with a sophisticated diamond necklace and matching earrings. The diamonds should sparkle realistically.',
  ),
];


