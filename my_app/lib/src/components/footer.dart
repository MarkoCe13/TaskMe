import 'package:flutter/material.dart';
import 'package:my_app/src/theme/app_colors.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 60),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.checklist,
              size: 38,
               color: AppColors.taskMeGreen,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/tasks');
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.auto_awesome,
              size: 38,
               color: AppColors.taskMeGreen,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/daily-plan');
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle,
              size: 38,
               color: AppColors.taskMeGreen,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/add');
            },
          ),
        ],
      ),
    );
  }
}
