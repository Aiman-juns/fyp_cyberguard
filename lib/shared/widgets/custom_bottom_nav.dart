import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const CustomBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SalomonBottomBar(
      currentIndex: currentIndex,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey.shade600,
      onTap: onTabChanged,
      items: [
        SalomonBottomBarItem(
          icon: const Icon(Icons.library_books),
          title: const Text('Resources'),
          selectedColor: Colors.purple,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.school),
          title: const Text('Training'),
          selectedColor: Colors.pink,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.security),
          title: const Text('Assistant'),
          selectedColor: Colors.orange,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.trending_up),
          title: const Text('Performance'),
          selectedColor: Colors.teal,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.newspaper),
          title: const Text('News'),
          selectedColor: Colors.blue,
        ),
      ],
    );
  }
}
