import 'package:flutter/material.dart';
import '../../widgets/profile_header_action.dart';
import '../../services/firestore_service.dart';
import '../../models/item_model.dart';
import 'package:latlong2/latlong.dart';
import 'item_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../widgets/screen_header.dart';
import 'map_screen.dart';
import 'package:geolocator/geolocator.dart';

class ItemListScreen extends StatefulWidget {
  @override
  _ItemListScreenState createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedTab = 0; // 0: All, 1: Lost, 2: Found
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<ItemModel> _searchResults = [];

  bool _nearbyOnly = false;
  LatLng? _userLocation;
  bool _isLocating = false;

  final List<String> _categories = [
    'All',
    'Electronics',
    'Documents',
    'Accessories',
    'Bags',
    'Keys',
    'Clothing',
    'Books',
    'Other',
  ];

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _firestoreService.searchItems(query);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    setState(() => _isLocating = true);
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('Error getting location for list: $e');
    } finally {
      setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine streams outside for cleaner build
    String type =
        _selectedTab == 0 ? 'all' : (_selectedTab == 1 ? 'lost' : 'found');
    Stream<List<ItemModel>> itemsStream;
    if (type == 'all') {
      itemsStream = _selectedCategory == 'All'
          ? _firestoreService.getItemsStream()
          : _firestoreService.getItemsByCategory(_selectedCategory);
    } else {
      itemsStream = _firestoreService.getItemsByType(type);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Discover',
              subtitle: 'Find lost items nearby',
              action: ProfileHeaderAction(),
            ),
            _buildSearchBar(),
            Expanded(
              child: StreamBuilder<List<ItemModel>>(
                stream:
                    _isSearching ? Stream.value(_searchResults) : itemsStream,
                builder: (context, snapshot) {
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildTabSelector()),
                      SliverToBoxAdapter(child: _buildCategoryFilter()),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (snapshot.hasError)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('Error loading items')),
                        )
                      else
                        () {
                          final items = snapshot.data ?? [];
                          if (items.isEmpty) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(
                                  _isSearching
                                      ? 'No results found'
                                      : 'No items found',
                                  _isSearching
                                      ? 'Try searching for something else'
                                      : 'Be the first to post!'),
                            );
                          }

                          // Apply Nearby Filter
                          final filteredItems =
                              !_nearbyOnly || _userLocation == null
                                  ? items
                                  : items.where((item) {
                                      if (item.latitude == null ||
                                          item.longitude == null) return false;
                                      final distance =
                                          Geolocator.distanceBetween(
                                        _userLocation!.latitude,
                                        _userLocation!.longitude,
                                        item.latitude!,
                                        item.longitude!,
                                      );
                                      return distance <= 10000; // 10km
                                    }).toList();

                          if (filteredItems.isEmpty) {
                            return SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState('No nearby items',
                                  'Try expanding your search'),
                            );
                          }

                          return _buildSliverGrid(filteredItems);
                        }(),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'map_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        },
        label: const Text('Map View'),
        icon: const Icon(Icons.map_rounded),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: Theme.of(context).primaryColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for lost items...',
            prefixIcon: Icon(Icons.search_rounded,
                color: Theme.of(context).primaryColor),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  ),
                if (_isLocating)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _nearbyOnly
                        ? Icons.near_me_rounded
                        : Icons.near_me_outlined,
                    color: _nearbyOnly
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  tooltip: 'Nearby Only (10km)',
                  onPressed: () {
                    if (_userLocation == null) {
                      _fetchUserLocation();
                    }
                    setState(() => _nearbyOnly = !_nearbyOnly);
                  },
                ),
              ],
            ),
            filled: true,
            fillColor:
                Colors.grey[50], // Slightly lighter than standard grey[100]
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          onChanged: _performSearch,
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(3),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton('All', 0),
          _buildTabButton('Lost', 1),
          _buildTabButton('Found', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    final activeColor = index == 1
        ? const Color(0xFFFF8C7A) // Coral for Lost
        : (index == 2
            ? const Color(0xFF43A047)
            : Theme.of(context).primaryColor); // Green for Found / Teal for All

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // _buildItemsGrid logic moved into build's StreamBuilder for sliver support

  Widget _buildSliverGrid(List<ItemModel> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.70,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildItemCard(items[index]),
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildItemCard(ItemModel item) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(item: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'item_${item.id}',
                    child: CachedNetworkImage(
                      imageUrl: item.images.first,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[100],
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[100],
                        child: Icon(Icons.broken_image_rounded,
                            color: Colors.grey[400]),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        timeago.format(item.createdAt, locale: 'en_short'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.type == 'lost'
                            ? const Color(0xFFFF8C7A)
                            : const Color(0xFF43A047),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        item.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 12, color: Colors.grey[500]),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            if (item.latitude != null && item.longitude != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            MapScreen(focusItem: item),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      if (_userLocation != null)
                                        Text(
                                          '${(Geolocator.distanceBetween(_userLocation!.latitude, _userLocation!.longitude, item.latitude!, item.longitude!) / 1000).toStringAsFixed(1)}km • ',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      Icon(
                                        Icons.map_rounded,
                                        size: 16,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (item.status != 'active')
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.status == 'claimed'
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: item.status == 'claimed'
                                ? Colors.orange
                                : Colors.blue,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          item.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.status == 'claimed'
                                ? Colors.orange[800]
                                : Colors.blue[800],
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
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.manage_search_rounded,
                size: 64, color: Colors.grey[300]),
          ),
          SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
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
