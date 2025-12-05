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
          icon: const Icon(Icons.home_filled),
          title: const Text('Home'),
          selectedColor: Colors.blue,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.smart_toy_outlined),
          title: const Text('Assistant'),
          selectedColor: Colors.orange,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.bar_chart),
          title: const Text('Performance'),
          selectedColor: Colors.teal,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.sports_esports),
          title: const Text('Games'),
          selectedColor: Colors.purple,
        ),
        SalomonBottomBarItem(
          icon: const Icon(Icons.person_outline),
          title: const Text('Profile'),
          selectedColor: Colors.green,
        ),
      ],
    );
  }
}
