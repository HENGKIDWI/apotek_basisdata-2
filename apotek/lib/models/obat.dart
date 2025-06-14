class Obat {
  final int? id; // id bisa null saat membuat obat baru
  final String nama;
  final String jenis;
  final double harga;
  final int stok;
  final DateTime expiredDate;

  Obat({
    this.id,
    required this.nama,
    required this.jenis,
    required this.harga,
    required this.stok,
    required this.expiredDate,
  });

  factory Obat.fromMap(Map<String, dynamic> map) {
    return Obat(
      id: map['id_obat'],
      nama: map['nama_obat'],
      jenis: map['jenis'],
      harga: (map['harga'] as num).toDouble(),
      stok: map['stok'],
      expiredDate: DateTime.parse(map['expired_date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_obat': id, // Di Go, kita abaikan ini saat INSERT
      'nama_obat': nama,
      'jenis': jenis,
      'harga': harga,
      'stok': stok,
      'expired_date': expiredDate.toUtc().toIso8601String(),
    };
  }
}
