import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/unread_messages_service.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/home/item_list_screen.dart';
import '../screens/home/post_item_screen.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    UnreadMessagesService().init();
  }

  final List<Widget> _screens = [
    ItemListScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  DateTime? _currentBackPressTime;

  void _handleBackPress() {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return;
    }

    DateTime now = DateTime.now();
    if (_currentBackPressTime == null ||
        now.difference(_currentBackPressTime!) > Duration(seconds: 2)) {
      _currentBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Press back again to exit'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          width: 200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Exit app
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    // PopScope for handling back button on newer Flutter versions
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        // Use IndexedStack to preserve state
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildNavigationBar(context),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PostItemScreen()),
                  );
                },
                icon: Icon(Icons.add_rounded),
                label: Text('Post Item',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                elevation: 4,
              )
            : null,
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(
                  0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              ValueListenableBuilder<int>(
                valueListenable: UnreadMessagesService().unreadCountNotifier,
                builder: (context, count, child) {
                  return Badge(
                    label: Text('$count'),
                    isLabelVisible: count > 0,
                    child: _buildNavBarItem(1, Icons.chat_bubble_rounded,
                        Icons.chat_bubble_outline, 'Chats'),
                  );
                },
              ),
              _buildNavBarItem(
                  2, Icons.person_rounded, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(
      int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final isSelected = _currentIndex == index;
    final primaryColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? primaryColor : Colors.grey[500],
              size: 26,
            ),
            AnimatedSize(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: SizedBox(
                width: isSelected ? 8 : 0,
              ),
            ),
            if (isSelected)
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
