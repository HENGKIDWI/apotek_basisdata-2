// lib/screens/laporan_screen.dart
import 'package:apotek/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // DefaultTabController akan mengelola state dari TabBar dan TabBarView
    return DefaultTabController(
      length: 2, // Kita punya 2 tab
      child: Scaffold(
        appBar: AppBar(
          // AppBar ini berada di dalam Scaffold Laporan, bukan AppBar utama
          // Ini membuatnya seolah-olah menyatu dengan halaman
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          flexibleSpace: const TabBar(
            tabs: [Tab(text: 'Stok Menipis'), Tab(text: 'Penjualan Harian')],
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: const TabBarView(
          children: [
            // Konten untuk tab pertama
            LaporanStokMenipisView(),
            // Konten untuk tab kedua
            LaporanPenjualanView(),
          ],
        ),
      ),
    );
  }
}

// Widget terpisah untuk Laporan Stok Menipis
class LaporanStokMenipisView extends StatefulWidget {
  const LaporanStokMenipisView({super.key});

  @override
  State<LaporanStokMenipisView> createState() => _LaporanStokMenipisViewState();
}

class _LaporanStokMenipisViewState extends State<LaporanStokMenipisView> {
  final ApiService apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _futureLaporan;

  @override
  void initState() {
    super.initState();
    _futureLaporan = apiService.getLaporanStokMenipis();
  }

  @override
  Widget build(BuildContext context) {
    // Ini adalah kode FutureBuilder yang sudah kita buat sebelumnya
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureLaporan,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final laporanData = snapshot.data!;
          return ListView.builder(
            itemCount: laporanData.length,
            itemBuilder: (context, index) {
              final item = laporanData[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: ListTile(
                  title: Text(item['nama_obat'].toString()),
                  trailing: Text(
                    'Sisa Stok: ${item['stok']}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          return const Center(
            child: Text("Tidak ada obat yang stoknya menipis."),
          );
        }
      },
    );
  }
}

// Widget terpisah untuk Laporan Penjualan Harian
class LaporanPenjualanView extends StatefulWidget {
  const LaporanPenjualanView({super.key});

  @override
  State<LaporanPenjualanView> createState() => _LaporanPenjualanViewState();
}

class _LaporanPenjualanViewState extends State<LaporanPenjualanView> {
  final ApiService apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _futureLaporan;

  @override
  void initState() {
    super.initState();
    _futureLaporan = apiService.getLaporanPenjualanHarian();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureLaporan,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final laporanData = snapshot.data!;
          return ListView.builder(
            itemCount: laporanData.length,
            itemBuilder: (context, index) {
              final item = laporanData[index];
              // Format tanggal agar lebih mudah dibaca
              final tanggal = DateTime.parse(item['tanggal_penjualan']);
              final formattedDate = DateFormat(
                'EEEE, d MMMM yyyy',
                'id_ID',
              ).format(tanggal);
              final formattedTotal = NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              ).format(item['total_penjualan']);

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: ListTile(
                  title: Text(
                    formattedDate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Jumlah Transaksi: ${item['jumlah_transaksi']}',
                  ),
                  trailing: Text(
                    formattedTotal,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          return const Center(child: Text("Belum ada data penjualan."));
        }
      },
    );
  }
}
