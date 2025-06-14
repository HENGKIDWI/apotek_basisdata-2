import 'package:apotek/models/obat.dart';
import 'package:apotek/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Nama class diubah agar lebih generik
class FormObatScreen extends StatefulWidget {
  // Tambahkan parameter opsional untuk menampung data obat saat mode edit
  final Obat? obat;

  const FormObatScreen({super.key, this.obat});

  @override
  State<FormObatScreen> createState() => _FormObatScreenState();
}

class _FormObatScreenState extends State<FormObatScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  late bool _isEditMode;

  final _namaController = TextEditingController();
  final _jenisController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();
  final _expiredDateController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.obat != null;

    if (_isEditMode) {
      // Isi semua field jika ini adalah mode edit
      final obat = widget.obat!;
      _namaController.text = obat.nama;
      _jenisController.text = obat.jenis;
      _hargaController.text = obat.harga.toString();
      _stokController.text = obat.stok.toString();
      _selectedDate = obat.expiredDate;
      _expiredDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(obat.expiredDate);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Buat objek Obat dari data form
        final obatData = Obat(
          id: _isEditMode ? widget.obat!.id : null,
          nama: _namaController.text,
          jenis: _jenisController.text,
          harga: double.parse(_hargaController.text),
          stok: int.parse(_stokController.text),
          expiredDate: _selectedDate!,
        );

        if (_isEditMode) {
          await _apiService.updateObat(widget.obat!.id!, obatData);
        } else {
          await _apiService.createObat(obatData);
        }

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Obat berhasil ${_isEditMode ? 'diperbarui' : 'ditambahkan'}!',
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _expiredDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Obat' : 'Tambah Obat Baru'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Obat'),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _jenisController,
                decoration: const InputDecoration(labelText: 'Jenis Obat'),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Jenis tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _hargaController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value!.isEmpty ? 'Harga tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _stokController,
                decoration: const InputDecoration(labelText: 'Stok Awal'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value!.isEmpty ? 'Stok tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _expiredDateController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Kadaluwarsa',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator:
                    (value) =>
                        value!.isEmpty ? 'Tanggal tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
