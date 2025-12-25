import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/item_model.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onTap;

  const ItemCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (item.images.isNotEmpty)
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: item.images.first,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: Icon(Icons.error),
                    ),
                  ),
                  // Type badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: item.type == 'lost' ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.type.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Status badge (NEW!)
                  if (item.status != 'active')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: item.status == 'claimed' 
                              ? Colors.orange 
                              : Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.status.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Image count
                  if (item.images.length > 1)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.image, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${item.images.length}',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  
                  // Description
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  
                  // Category and Location
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(item.category),
                        backgroundColor: Colors.blue[50],
                        labelStyle: TextStyle(fontSize: 12),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (item.location.isNotEmpty)
                        Chip(
                          label: Text(item.location),
                          avatar: Icon(Icons.location_on, size: 16),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(fontSize: 12),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  
                  // Posted by and time
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        child: Text(
                          item.postedByName[0].toUpperCase(),
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        item.postedByName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Text(
                        timeago.format(item.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
