// lib/screens/transaksi_screen.dart
import 'package:apotek/models/obat.dart';
import 'package:apotek/models/transaksi.dart';
import 'package:apotek/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Obat>> _futureObat;
  // Map untuk menampung keranjang belanja <id_obat, DetailTransaksi>
  final Map<int, DetailTransaksi> _keranjang = {};
  double _totalHarga = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _futureObat = _apiService.getObat();
  }

  void _hitungTotal() {
    _totalHarga = 0.0;
    _keranjang.forEach((key, detail) {
      _totalHarga += detail.subtotal;
    });
    setState(() {});
  }

  void _tambahKeKeranjang(Obat obat) {
    if (_keranjang.containsKey(obat.id)) {
      // Jika sudah ada, tambah jumlahnya
      _keranjang[obat.id]!.jumlah++;
    } else {
      // Jika belum ada, tambahkan ke keranjang
      _keranjang[obat.id!] = DetailTransaksi(obat: obat, jumlah: 1);
    }
    _hitungTotal();
  }

  void _kurangiDariKeranjang(Obat obat) {
    if (_keranjang.containsKey(obat.id)) {
      if (_keranjang[obat.id]!.jumlah > 1) {
        _keranjang[obat.id]!.jumlah--;
      } else {
        // Jika jumlahnya 1, hapus dari keranjang
        _keranjang.remove(obat.id);
      }
      _hitungTotal();
    }
  }

  Future<void> _submitTransaksi() async {
    if (_keranjang.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Keranjang masih kosong!')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Siapkan payload sesuai format yang diharapkan Go
    final payload = {
      "id_pelanggan": null,
      "total_harga": _totalHarga,
      "items":
          _keranjang.values
              .map(
                (detail) => {
                  "id_obat": detail.obat.id,
                  "jumlah": detail.jumlah,
                  "harga_satuan": detail.obat.harga,
                  "subtotal": detail.subtotal,
                },
              )
              .toList(),
    };

    try {
      await _apiService.createTransaksi(payload);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil disimpan!')),
      );
      // Kosongkan keranjang setelah berhasil
      setState(() {
        _keranjang.clear();
        _hitungTotal();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      body: Column(
        children: [
          // Bagian Keranjang
          Expanded(
            flex: 1,
            child:
                _keranjang.isEmpty
                    ? const Center(child: Text('Keranjang Belanja Kosong'))
                    : ListView.builder(
                      itemCount: _keranjang.length,
                      itemBuilder: (context, index) {
                        final detail = _keranjang.values.elementAt(index);
                        return ListTile(
                          title: Text(detail.obat.nama),
                          subtitle: Text(
                            '${formatCurrency.format(detail.obat.harga)} x ${detail.jumlah}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatCurrency.format(detail.subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    () => _kurangiDariKeranjang(detail.obat),
                                icon: const Icon(Icons.remove_circle),
                              ),
                              IconButton(
                                onPressed:
                                    () => _tambahKeKeranjang(detail.obat),
                                icon: const Icon(Icons.add_circle),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
          // Total dan Tombol Simpan
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${formatCurrency.format(_totalHarga)}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitTransaksi,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Simpan Transaksi'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Bagian Daftar Obat
          Expanded(
            flex: 1,
            child: FutureBuilder<List<Obat>>(
              future: _futureObat,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (snapshot.hasData) {
                  final obats = snapshot.data!;
                  return ListView.builder(
                    itemCount: obats.length,
                    itemBuilder: (context, index) {
                      final obat = obats[index];
                      return ListTile(
                        title: Text(obat.nama),
                        subtitle: Text('Stok: ${obat.stok}'),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.green,
                          ),
                          onPressed: () => _tambahKeKeranjang(obat),
                        ),
                      );
                    },
                  );
                }
                return const Center(child: Text("Tidak ada data obat."));
              },
            ),
          ),
        ],
      ),
    );
  }
}
