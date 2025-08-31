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
    name: 'Elegant Saree',
    imageAssetPath: 'assets/images/saree/saree1.jpg',
    prompt:
        "Please replace the person's current clothing with the exact saree shown in the second image. Apply the saree's design, colors, patterns, and draping style to the person in the first image. Ensure the saree fits naturally on the person's body posture and maintains realistic lighting and shadows.",
  ),
  CatalogItem(
    id: 'd2',
    name: 'Designer Saree',
    imageAssetPath: 'assets/images/saree/saree2.jpg',
    prompt:
        'Replace the person\'s outfit with the exact saree from the second image. Copy all the design details, colors, embroidery, and fabric texture from the catalog saree onto the person in the first image. Make sure the draping looks natural and appropriate for the person\'s pose.',
  ),
  CatalogItem(
    id: 'd3',
    name: 'Traditional Saree',
    imageAssetPath: 'assets/images/saree/saree3.jpg',
    prompt:
        "Transform the person's clothing to match the exact saree shown in the second image. Apply the same design, color scheme, patterns, and traditional elements from the catalog saree to the person. Ensure realistic fit and natural draping.",
  ),
  CatalogItem(
    id: 'd4',
    name: 'Festive Saree',
    imageAssetPath: 'assets/images/saree/saree4.jpg',
    prompt:
        'Dress the person in the exact saree from the second image. Transfer all visual elements including colors, patterns, embellishments, and styling from the catalog saree to the person in the first image. Maintain natural body proportions and realistic fabric behavior.',
  ),
  CatalogItem(
    id: 'd5',
    name: 'Contemporary Saree',
    imageAssetPath: 'assets/images/saree/saree5.jpg',
    prompt:
        'Apply the exact saree design from the second image to the person in the first image. Copy the saree\'s style, colors, patterns, and modern elements. Ensure the virtual try-on looks realistic with proper fit, draping, and lighting that matches the original photo.',
  ),
];

const List<CatalogItem> jewelryCatalog = [
  CatalogItem(
    id: 'j1',
    name: 'Temple Necklace',
    imageAssetPath: 'assets/images/jewelry/j1.jpg',
    prompt:
        "Add the exact necklace shown in the second image to the person in the first image. Place the jewelry naturally around the person's neck, ensuring it fits properly with their pose and clothing. Maintain realistic lighting and shadows that match the original photo.",
  ),
  CatalogItem(
    id: 'j2',
    name: 'Kundan Choker',
    imageAssetPath: 'assets/images/jewelry/j2.jpg',
    prompt:
        'Apply the exact choker necklace from the second image to the person in the first image. Position the jewelry correctly around the neck, matching the design, colors, and gemstone details from the catalog item. Ensure natural placement and realistic appearance.',
  ),
  CatalogItem(
    id: 'j3',
    name: 'Chandbali Earrings',
    imageAssetPath: 'assets/images/jewelry/j3.jpg',
    prompt:
        "Add the exact earrings shown in the second image to the person's ears in the first image. Copy the design, shape, color, and decorative elements from the catalog earrings. Ensure they hang naturally and match the person's hair and pose.",
  ),
  CatalogItem(
    id: 'j4',
    name: 'Maang Tikka',
    imageAssetPath: 'assets/images/jewelry/j4.jpg',
    prompt:
        "Place the exact maang tikka from the second image on the person's forehead in the first image. Position the jewelry correctly on the hairline, copying all design details, gems, and chain elements from the catalog item. Ensure it fits naturally with the person's hair and face.",
  ),
  CatalogItem(
    id: 'j5',
    name: 'Diamond Set',
    imageAssetPath: 'assets/images/jewelry/j5.jpg',
    prompt:
        'Add the exact jewelry set from the second image to the person in the first image. Apply both the necklace and earrings, copying all design elements, diamonds, and styling details. Ensure realistic placement, lighting, and sparkle effects that match the original photo quality.',
  ),
];


