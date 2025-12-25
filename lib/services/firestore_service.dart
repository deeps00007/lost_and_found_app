import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all items stream
  Stream<List<ItemModel>> getItemsStream() {
    return _firestore
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ItemModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get items by type (lost or found)
  Stream<List<ItemModel>> getItemsByType(String type) {
    return _firestore
        .collection('items')
        .where('type', isEqualTo: type)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ItemModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get items by category
  Stream<List<ItemModel>> getItemsByCategory(String category) {
    return _firestore
        .collection('items')
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ItemModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Get user's items
  Stream<List<ItemModel>> getUserItems(String userId) {
    return _firestore
        .collection('items')
        .where('postedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ItemModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Search items
  Future<List<ItemModel>> searchItems(String query) async {
    final snapshot = await _firestore
        .collection('items')
        .where('status', isEqualTo: 'active')
        .get();

    return snapshot.docs
        .map((doc) => ItemModel.fromMap(doc.id, doc.data()))
        .where((item) =>
            item.title.toLowerCase().contains(query.toLowerCase()) ||
            item.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Update item status
Future<void> updateItemStatus(String itemId, String status) async {
  await _firestore.collection('items').doc(itemId).update({
    'status': status,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}


  // Delete item
  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }
}
