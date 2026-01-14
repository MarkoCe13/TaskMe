import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_app/src/screens/HomeScreen.dart';
import 'package:my_app/src/screens/SignUp.dart';
import 'package:my_app/src/theme/app_colors.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container( // ✅ ADDED
      decoration: BoxDecoration( // ✅ ADDED
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2), // shadow DOWN like footer
            blurRadius: 4,
          ),
        ],
      ),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0, // ✅ IMPORTANT: disable AppBar shadow
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset(
              'assets/images/taskme.png',
              height: 180,
            ),
            const Spacer(),
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
                color: AppColors.taskMeGreen,
                size: 28,
              ),
            ),
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
                color: AppColors.taskMeGreen,
                size: 26,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
