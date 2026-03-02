import 'dart:async'; // ✅ Added
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'pages/beranda.dart';
import 'pages/informasi.dart';
import 'pages/keuangan.dart';
import 'pages/inventaris.dart';
import 'pages/akun.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  StreamSubscription? _notifSubscription; // ✅ Added
  bool _firstLoad = true; // ✅ Used to ignore old history on startup

  @override
  void initState() {
    super.initState();
    _initNotificationListener();
  }

  @override
  void dispose() {
    _notifSubscription?.cancel(); // ✅ Clean up listener
    super.dispose();
  }

  /// ✅ Global real-time listener for notifications
  void _initNotificationListener() {
    // We use a flag to skip the very first "historical" record when the app starts
    bool isInitialData = true;

    _notifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {

      // 1. Skip the data that existed before the app was opened
      if (isInitialData) {
        isInitialData = false;
        return;
      }

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final msg = data['message'] as String? ?? 'Ada pembaruan transaksi.';

        // 2. Log to console so you can verify the listener is firing
        debugPrint('🔔 Notification received: $msg');

        // 3. Show the SnackBar
        // Use a unique key or ClearSnackBars to prevent overlap if multiple edits happen fast
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(msg)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 5),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }, onError: (error) {
      debugPrint('❌ Notification Listener Error: $error');
    });
  }

  final _pages = const <Widget>[
    BerandaPage(),
    InformasiPage(),
    KeuanganPage(),
    InventarisPage(),
    AkunPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: _pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Informasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Keuangan',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventaris',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}