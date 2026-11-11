import 'package:image_picker/image_picker.dart';

import 'package:ecoenzyme/features/screens/ecoai.dart';
import 'package:ecoenzyme/features/screens/main_screen.dart';
import 'package:ecoenzyme/features/screens/scan_screen.dart';
import 'package:ecoenzyme/features/screens/setting.dart';
import 'package:ecoenzyme/features/tasks/task_screen.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  int _homeRefreshTrigger = 0;
  final _pendingCrop = ValueNotifier<XFile?>(null);

  static const _titles = [
    'Ecoenzyme',
    'EcoAI',
    'Crop photo',
    'My tasks',
    'Settings',
  ];

  @override
  void dispose() {
    _pendingCrop.dispose();
    super.dispose();
  }

  void _openCropInChat(XFile image) {
    _pendingCrop.value = image;
    setState(() => _selectedIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      MainScreen(refreshTrigger: _homeRefreshTrigger),
      Ecoai(pendingCrop: _pendingCrop),
      ScanScreen(onImageSelected: _openCropInChat),
      const TaskScreen(),
      const Setting(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Icon(Icons.eco_outlined),
        ),
        leadingWidth: 48,
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            if (index == 0 && _selectedIndex != 0) _homeRefreshTrigger++;
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'EcoAI',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
