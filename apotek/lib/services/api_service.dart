// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/obat.dart';

class ApiService {
  // PENTING:
  // - Jika menjalankan di Android Emulator, gunakan '10.0.2.2'.
  // - Jika menjalankan di iOS Simulator, gunakan 'localhost'.
  // - Jika menjalankan di device fisik, gunakan IP lokal komputer Anda (misal: '192.168.1.5').
  final String _baseUrl = "http://192.168.1.125:8080/api";

  Future<List<Obat>> getObat() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/obat'));

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        final List<Obat> obats =
            body.map((dynamic item) => Obat.fromMap(item)).toList();
        return obats;
      } else {
        throw "Gagal memuat data obat. Status code: ${response.statusCode}";
      }
    } catch (e) {
      throw "Terjadi error: $e";
    }
  }

  // Fungsi untuk mendapatkan laporan stok menipis
  Future<List<Map<String, dynamic>>> getLaporanStokMenipis() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/laporan/stok-menipis'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        // Karena datanya sederhana, kita bisa langsung menggunakan List<Map<String, dynamic>>
        return body.cast<Map<String, dynamic>>();
      } else {
        throw "Gagal memuat laporan stok. Status code: ${response.statusCode}";
      }
    } catch (e) {
      throw "Terjadi error: $e";
    }
  }

  // Fungsi untuk mendapatkan laporan penjualan harian
  Future<List<Map<String, dynamic>>> getLaporanPenjualanHarian() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/laporan/penjualan-harian'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.cast<Map<String, dynamic>>();
      } else {
        throw "Gagal memuat laporan penjualan. Status code: ${response.statusCode}";
      }
    } catch (e) {
      throw "Terjadi error: $e";
    }
  }

  Future<void> createObat(Obat obat) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/obat'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(obat.toMap()),
      );

      if (response.statusCode != 201) {
        // 201 artinya Created
        throw "Gagal menambahkan obat. Status code: ${response.statusCode}";
      }
    } catch (e) {
      throw "Terjadi error: $e";
    }
  }

  // Fungsi untuk memperbarui obat berdasarkan ID
  Future<void> updateObat(int id, Obat obat) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/obat/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(obat.toMap()),
      );

      if (response.statusCode != 200) {
        throw "Gagal memperbarui obat. Status code: ${response.statusCode}";
      }
    } catch (e) {
      throw "Terjadi error: $e";
    }
  }

  // Fungsi untuk menghapus obat berdasarkan ID
  Future<void> deleteObat(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/obat/$id'));

      if (response.statusCode != 200) {
        throw "Gagal menghapus obat. Status code: ${response.statusCode}";
      }
    } catch (e) {
      throw "Terjadi error: $e";
    }
  }

  // Fungsi untuk membuat transaksi baru
  Future<void> createTransaksi(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/transaksi'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 201) {
        // Coba decode error message dari server jika ada
        final errorBody = jsonDecode(response.body);
        throw "Gagal membuat transaksi: ${errorBody['error'] ?? response.body}";
      }
    } catch (e) {
      throw "Terjadi error: $e";
    }
  }
}
