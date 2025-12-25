import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ProfileHeaderAction extends StatelessWidget {
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return SizedBox();

    return StreamBuilder<UserModel?>(
      stream: _authService.getUserDataStream(currentUser!.uid),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final photoUrl = user?.profilePicUrl ?? currentUser?.photoURL;
        final displayName = user?.name ?? currentUser?.displayName ?? 'U';

        return Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  const Color.fromARGB(255, 1, 90, 84).withValues(alpha: 0.9),
              width: 1,
            ),
          ),
          child: CircleAvatar(
            backgroundColor: Colors.grey[100],
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    displayName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
