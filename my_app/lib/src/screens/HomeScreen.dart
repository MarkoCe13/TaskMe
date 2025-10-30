import 'package:flutter/material.dart';
import '../components/header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      body: const Center(child: Text('Home content here')),
    );
  }
}
