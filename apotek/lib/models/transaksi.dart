// lib/models/transaksi.dart
import 'package:apotek/models/obat.dart';

// Class ini hanya untuk membantu di sisi UI Flutter
class DetailTransaksi {
  final Obat obat;
  int jumlah;

  DetailTransaksi({required this.obat, this.jumlah = 1});

  double get subtotal => obat.harga * jumlah;
}
