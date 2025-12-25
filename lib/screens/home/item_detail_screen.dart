import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/item_model.dart';
import '../chat/chat_room_screen.dart';
import '../../services/firestore_service.dart';
import 'map_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;

  ItemDetailScreen({required this.item});

  @override
  _ItemDetailScreenState createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  void _startChat(BuildContext context) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (currentUserId == widget.item.postedBy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You cannot chat with yourself'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          otherUserId: widget.item.postedBy,
          otherUserName: widget.item.postedByName,
          itemId: widget.item.id,
          contextItem: widget.item, // Pass the item context
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          images: widget.item.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (currentUserId != widget.item.postedBy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only the owner can update status'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Update Item Status',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),
            _buildStatusOption(
              context,
              icon: Icons.check_circle_rounded,
              title: 'Mark as Claimed',
              subtitle: 'Someone has claimed this item',
              color: Colors.orange,
              status: 'claimed',
            ),
            _buildStatusOption(
              context,
              icon: Icons.done_all_rounded,
              title: 'Mark as Resolved',
              subtitle: 'Issue completely resolved',
              color: Colors.blue,
              status: 'resolved',
            ),
            _buildStatusOption(
              context,
              icon: Icons.refresh_rounded,
              title: 'Mark as Active',
              subtitle: 'Reopen this post',
              color: Colors.green,
              status: 'active',
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String status,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        await _updateStatus(context, status);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await _firestoreService.updateItemStatus(widget.item.id, newStatus);

      String message = '';
      if (newStatus == 'claimed') {
        message = 'Item marked as claimed!';
      } else if (newStatus == 'resolved') {
        message = 'Item marked as resolved!';
      } else {
        message = 'Item marked as active!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // No need to pop as we are already on the screen, setState will rebuild via Stream/Parent
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    if (currentUserId != widget.item.postedBy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only the owner can delete this post')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Post'),
        content: Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteItem(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              elevation: 0,
            ),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(BuildContext context) async {
    try {
      await _firestoreService.deleteItem(widget.item.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post deleted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final isOwner = currentUserId == widget.item.postedBy;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with Image Carousel
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            leading: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_rounded,
                    color: theme.colorScheme.primary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              if (isOwner)
                Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded,
                        color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'status') {
                        _showStatusDialog(context);
                      } else if (value == 'delete') {
                        _showDeleteDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'status',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                size: 20, color: theme.colorScheme.primary),
                            SizedBox(width: 12),
                            Text('Update Status'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 20, color: theme.colorScheme.error),
                            SizedBox(width: 12),
                            Text('Delete Post',
                                style:
                                    TextStyle(color: theme.colorScheme.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemCount: widget.item.images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showFullImage(context, index),
                        child: Hero(
                          tag:
                              'item_${widget.item.id}_img_$index', // Unique tag if needed, or simplistic
                          child: CachedNetworkImage(
                            imageUrl: widget.item.images[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => Icon(
                                Icons.broken_image_rounded,
                                color: Colors.grey[400]),
                          ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Dot indicators
                  if (widget.item.images.length > 1)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.item.images.length,
                          (index) => AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 30, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badges
                    Row(
                      children: [
                        _buildBadge(
                            context,
                            widget.item.type.toUpperCase(),
                            widget.item.type == 'lost'
                                ? const Color(0xFFFF8C7A)
                                : const Color(0xFF43A047),
                            widget.item.type == 'lost'
                                ? Icons.search_off_rounded
                                : Icons.check_circle_outline_rounded),
                        if (widget.item.status != 'active') ...[
                          SizedBox(width: 8),
                          _buildBadge(
                              context,
                              widget.item.status.toUpperCase(),
                              widget.item.status == 'claimed'
                                  ? Colors.orange
                                  : Colors.blue,
                              widget.item.status == 'claimed'
                                  ? Icons.emoji_events_outlined
                                  : Icons.done_all_rounded,
                              outlined: true),
                        ],
                      ],
                    ),
                    SizedBox(height: 20),

                    // Title
                    Text(
                      widget.item.title,
                      style: theme.textTheme.headlineMedium,
                    ),
                    SizedBox(height: 24),

                    // Info Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            icon: Icons.category_rounded,
                            label: 'Category',
                            value: widget.item.category,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            context,
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: DateFormat('MMM dd')
                                .format(widget.item.createdAt),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      icon: Icons.location_on_rounded,
                      label: 'Location',
                      value: widget.item.location,
                      fullWidth: true,
                    ),

                    if (widget.item.latitude != null &&
                        widget.item.longitude != null)
                      _buildMapPreview(context),

                    SizedBox(height: 24),
                    Text('Description', style: theme.textTheme.titleLarge),
                    SizedBox(height: 12),
                    Text(
                      widget.item.description.isNotEmpty
                          ? widget.item.description
                          : 'No description provided.',
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                    SizedBox(height: 32),

                    // Posted by
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              widget.item.postedByName.isNotEmpty
                                  ? widget.item.postedByName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Posted by',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  widget.item.postedByName,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _startChat(context),
              icon: Icon(Icons.chat_bubble_rounded),
              label: Text('Contact Owner'),
              elevation: 4,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBadge(
      BuildContext context, String text, Color color, IconData icon,
      {bool outlined = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: outlined ? color.withOpacity(0.1) : color,
        borderRadius: BorderRadius.circular(12),
        border: outlined ? Border.all(color: color) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: outlined ? color : Colors.white,
          ),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: outlined ? color : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(BuildContext context) {
    final location = LatLng(widget.item.latitude!, widget.item.longitude!);

    return Container(
      height: 180,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: location,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.lost_and_found_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: location,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.item.type == 'lost'
                            ? const Color(0xFFFF8C7A)
                            : const Color(0xFF43A047),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(focusItem: widget.item),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_rounded,
                          size: 16, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Open Full Map',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  FullScreenImageViewer({required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: images[index],
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        Icon(Icons.error, color: Colors.white),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
