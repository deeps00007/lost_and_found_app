import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/item_model.dart';
import '../../widgets/item_card.dart';
import '../home/item_detail_screen.dart';
import '../../widgets/screen_header.dart';

class MyPostsScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ScreenHeader(
            title: 'My Posts',
            subtitle: 'Items you have posted',
            showBackButton: true,
          ),
          Expanded(
            child: StreamBuilder<List<ItemModel>>(
              stream: _firestoreService.getUserItems(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.post_add_rounded,
                              size: 64, color: Colors.grey[400]),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start by posting a lost or found item',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: ItemCard(
                        item: item,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ItemDetailScreen(item: item),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
