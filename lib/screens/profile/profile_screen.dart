import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'my_posts_screen.dart';
import 'edit_profile_screen.dart';
import '../../widgets/screen_header.dart';

class ProfileScreen extends StatelessWidget {
  final AuthService _authService = AuthService();
  final User currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ScreenHeader(
            title: 'Profile',
            subtitle: 'Manage your account',
            action: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<UserModel?>(
              stream: _authService.getUserDataStream(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final user = snapshot.data;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: user?.profilePicUrl != null
                              ? NetworkImage(user!.profilePicUrl!)
                              : null,
                          child: user?.profilePicUrl == null
                              ? Text(
                                  currentUser.displayName?[0].toUpperCase() ??
                                      'U',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        currentUser.displayName ?? 'No Name',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        currentUser.email ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (user?.phoneNumber != null) ...[
                        SizedBox(height: 4),
                        Text(
                          user!.phoneNumber!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                      SizedBox(height: 32),
                      _buildMenuOption(
                        context,
                        title: 'My Posts',
                        icon: Icons.inventory_2_rounded,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyPostsScreen(),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      _buildMenuOption(
                        context,
                        title: 'Logout',
                        icon: Icons.logout_rounded,
                        color: Colors.red,
                        isDestructive: true,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Logout'),
                              content: Text('Are you sure you want to logout?'),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Logout',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await Provider.of<AuthProvider>(context,
                                    listen: false)
                                .signOut();
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? Colors.red : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
