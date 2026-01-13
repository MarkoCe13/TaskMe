import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/src/screens/HomeScreen.dart';
import 'package:my_app/src/screens/SignUp.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Image.asset(
            'assets/images/taskme.png',
            height: 180,
          ),
          const Spacer(),

          // Profile button
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
            icon: const Icon(
              Icons.person_outline,
              color: Colors.black87,
              size: 28,
            ),
          ),

          // Logout button
          IconButton(
            tooltip: 'Log out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                (route) => false,
              );
            },
            icon: const Icon(
              Icons.logout,
              color: Colors.black87,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
