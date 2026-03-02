import 'dart:async';
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
  StreamSubscription? _notifSubscription;

  // Track when the app opened to avoid showing historical popups
  final DateTime _appStartTime = DateTime.now();

  // Track last shown ID to prevent duplicate popups (local vs server triggers)
  String? _lastShownId;

  @override
  void initState() {
    super.initState();
    _initNotificationListener();
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  /// Robust real-time listener for notifications
  void _initNotificationListener() {
    _notifSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        final String msg = data['message'] as String? ?? 'Ada pembaruan transaksi.';
        final Timestamp? ts = data['timestamp'] as Timestamp?;

        // Logic: Only show if it's a new document ID we haven't handled yet
        // AND the timestamp is either null (local write) or after the app boot time.
        bool isNewDoc = _lastShownId != doc.id;
        bool isRecent = ts == null || ts.toDate().isAfter(_appStartTime);

        if (isNewDoc && isRecent) {
          // ✅ FIX: Check if the widget is still in the tree before using context
          if (!mounted) return;

          _lastShownId = doc.id;

          debugPrint('🔔 Notification received: $msg');

          final messenger = ScaffoldMessenger.of(context);
          final theme = Theme.of(context);

          messenger.clearSnackBars();
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(msg)),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.primary,
              duration: const Duration(seconds: 4),
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
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