import 'package:apotek/screens/laporan_screen.dart';
import 'package:apotek/screens/obat_screen.dart';
import 'package:apotek/screens/transaksi_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

// Versi baru yang sudah diperbaiki
Future<void> main() async {
  // Baris ini penting untuk memastikan Flutter siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data lokalisasi untuk bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apotek Baru',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan ditampilkan
  static const List<Widget> _widgetOptions = <Widget>[
    ObatScreen(),
    TransaksiScreen(),
    LaporanScreen(),
  ];

  // Daftar judul untuk setiap halaman
  static const List<String> _titleOptions = <String>[
    'Manajemen Obat',
    'Transaksi',
    'Laporan',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titleOptions.elementAt(_selectedIndex))),
      // Body akan menampilkan halaman sesuai item yang dipilih
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      // Membuat navigasi di bagian bawah
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            label: 'Obat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Laporan',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
