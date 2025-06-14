import 'package:flutter/material.dart';

import '../models/obat.dart';
import '../services/api_service.dart';
import 'tambah_obat_screen.dart'; // Kita akan gunakan FormObatScreen untuk tambah/edit

class ObatScreen extends StatefulWidget {
  const ObatScreen({super.key});

  @override
  State<ObatScreen> createState() => _ObatScreenState();
}

class _ObatScreenState extends State<ObatScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Obat>> _futureObat;

  @override
  void initState() {
    super.initState();
    _refreshObatList();
  }

  // Fungsi untuk mengambil atau menyegarkan daftar obat dari API
  void _refreshObatList() {
    setState(() {
      _futureObat = apiService.getObat();
    });
  }

  // Fungsi untuk navigasi ke halaman formulir (untuk mode Tambah atau Edit)
  void _navigateToForm({Obat? obat}) async {
    // Await `Navigator.push` untuk menunggu hasil dari halaman form
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormObatScreen(obat: obat)),
    );

    // Jika halaman form ditutup dan mengembalikan nilai 'true',
    // artinya ada data yang berhasil disimpan (tambah/edit).
    // Maka, kita refresh daftarnya.
    if (result == true) {
      _refreshObatList();
    }
  }

  // Fungsi untuk menampilkan dialog konfirmasi sebelum menghapus
  void _showDeleteConfirmation(Obat obat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Apakah Anda yakin ingin menghapus obat "${obat.nama}"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  Navigator.of(context).pop(); // Tutup dialog terlebih dahulu
                  await apiService.deleteObat(obat.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${obat.nama}" berhasil dihapus')),
                  );
                  _refreshObatList(); // Refresh daftar setelah berhasil hapus
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Obat>>(
        future: _futureObat,
        builder: (context, snapshot) {
          // Saat data sedang diambil
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Jika terjadi error
          else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          // Jika data berhasil didapat
          else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final obats = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: obats.length,
              itemBuilder: (context, index) {
                final obat = obats[index];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      obat.nama,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Stok: ${obat.stok}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol Edit
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _navigateToForm(obat: obat),
                          tooltip: 'Edit Obat',
                        ),
                        // Tombol Hapus
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(obat),
                          tooltip: 'Hapus Obat',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          // Jika tidak ada data
          else {
            return const Center(child: Text("Tidak ada data obat."));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () =>
                _navigateToForm(), // Panggil tanpa parameter untuk mode Tambah
        tooltip: 'Tambah Obat',
        child: const Icon(Icons.add),
      ),
    );
  }
}
