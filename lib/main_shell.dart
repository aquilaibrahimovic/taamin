import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'pages/beranda.dart';
import 'pages/informasi.dart';
import 'pages/keuangan.dart';
import 'pages/inventaris.dart';
import 'pages/akun.dart';
import 'widgets/common.dart';

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
      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      final data = doc.data();

      // message could be missing or not a String (defensive)
      final dynamic rawMsg = data['message'];
      final String msg = rawMsg is String && rawMsg.trim().isNotEmpty
          ? rawMsg
          : 'Ada pembaruan transaksi.';

      final Timestamp? ts = data['timestamp'] as Timestamp?;

      // Only show if it's a new document ID we haven't handled yet
      // AND the timestamp is either null (local write) or after the app boot time.
      final bool isNewDoc = _lastShownId != doc.id;
      final bool isRecent = ts == null || ts.toDate().isAfter(_appStartTime);

      if (!(isNewDoc && isRecent)) return;

      // ✅ Check if the widget is still in the tree before using context
      if (!mounted) return;

      _lastShownId = doc.id;

      debugPrint('🔔 Notification received: $msg');

      NotificationService.instance.showLocal(
        title: 'Keuangan',
        body: msg,
      );
      // ✅ Unified style: bottom bar + yesColor + info icon (from showAppSnackBar)
      showAppSnackBar(context, msg, kind: SnackKind.info);
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