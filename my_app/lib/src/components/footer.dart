import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 90),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.list, size: 40, color: Colors.black87),
            onPressed: () {
            Navigator.pushNamed(context, '/tasks');
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined, size: 40, color: Colors.black87),
            onPressed: () {
            Navigator.pushNamed(context, '/add');
            },
          ),
        ],
      ),
    );
  }
}
