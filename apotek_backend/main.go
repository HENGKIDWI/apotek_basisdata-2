package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql" // Tanda underscore berarti kita butuh efek sampingnya (registrasi driver)
	"github.com/gorilla/mux"
	"github.com/joho/godotenv"
)

// Struct untuk menampung data dari tabel 'obat'
// Perhatikan tag `json:"..."` untuk mengubah nama field saat di-encode ke JSON
type Obat struct {
	ID          int       `json:"id_obat"`
	NamaObat    string    `json:"nama_obat"`
	Jenis       string    `json:"jenis"`
	Harga       float64   `json:"harga"`
	Stok        int       `json:"stok"`
	ExpiredDate time.Time `json:"expired_date"`
}

// Struct untuk laporan stok menipis
type LaporanPenjualan struct {
	TanggalPenjualan string  `json:"tanggal_penjualan"`
	JumlahTransaksi  int     `json:"jumlah_transaksi"`
	TotalPenjualan   float64 `json:"total_penjualan"`
}

// Struct untuk menampung data dari Flutter
type DetailTransaksi struct {
	IDObat   int     `json:"id_obat"`
	Jumlah   int     `json:"jumlah"`
	Harga    float64 `json:"harga_satuan"`
	Subtotal float64 `json:"subtotal"`
}
type TransaksiPayload struct {
	IDPelanggan sql.NullInt64     `json:"id_pelanggan"` // Bisa null
	TotalHarga  float64           `json:"total_harga"`
	Items       []DetailTransaksi `json:"items"`
}

// Variabel global untuk koneksi database
var db *sql.DB

func main() {
	// Muat variabel dari file .env
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	// Buat DSN (Data Source Name) untuk koneksi database
	dsn := fmt.Sprintf("%s:%s@tcp(%s)/%s?parseTime=true",
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_HOST"),
		os.Getenv("DB_DATABASE"),
	)

	// Buka koneksi ke database
	db, err = sql.Open("mysql", dsn)
	if err != nil {
		log.Fatal("Gagal terhubung ke database:", err)
	}
	defer db.Close()

	// Cek apakah koneksi benar-benar hidup
	err = db.Ping()
	if err != nil {
		log.Fatal("Database tidak merespon:", err)
	}
	fmt.Println("Terhubung ke database MySQL!")

	// Inisialisasi router
	r := mux.NewRouter()

	// Definisikan rute (endpoints)
	r.HandleFunc("/api/obat", getObatHandler).Methods("GET")
	r.HandleFunc("/api/obat", createObatHandler).Methods("POST")
	r.HandleFunc("/api/obat/{id}", updateObatHandler).Methods("PUT")
	r.HandleFunc("/api/obat/{id}", deleteObatHandler).Methods("DELETE")
	r.HandleFunc("/api/transaksi", createTransaksiHandler).Methods("POST")
	r.HandleFunc("/api/laporan/stok-menipis", getLaporanStokMenipisHandler).Methods("GET")
	r.HandleFunc("/api/laporan/penjualan-harian", getLaporanPenjualanHandler).Methods("GET")
	r.HandleFunc("/api/resep/proses/{id_resep}", prosesResepHandler).Methods("POST")

	port := os.Getenv("API_PORT")
	fmt.Printf("Server API berjalan di http://localhost:%s\n", port)
	log.Fatal(http.ListenAndServe(":"+port, r))
}

// Handler untuk mengambil semua data obat
func getObatHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query("SELECT * FROM obat")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var obats []Obat
	for rows.Next() {
		var obat Obat
		if err := rows.Scan(&obat.ID, &obat.NamaObat, &obat.Jenis, &obat.Harga, &obat.Stok, &obat.ExpiredDate); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		obats = append(obats, obat)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(obats)
}

// Handler untuk laporan stok menipis
func getLaporanStokMenipisHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query("SELECT id_obat, nama_obat, stok FROM view_stok_menipis")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Kita akan membuat slice of map untuk menampung hasil
	var results []map[string]interface{}
	for rows.Next() {
		var id_obat, stok int
		var nama_obat string
		if err := rows.Scan(&id_obat, &nama_obat, &stok); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		result := map[string]interface{}{
			"id_obat":   id_obat,
			"nama_obat": nama_obat,
			"stok":      stok,
		}
		results = append(results, result)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

// Handler untuk memproses resep
func prosesResepHandler(w http.ResponseWriter, r *http.Request) {
	// Ambil id_resep dari URL
	vars := mux.Vars(r)
	idResep := vars["id_resep"]

	// Panggil Stored Procedure
	_, err := db.Exec("CALL sp_proses_resep_obat(?)", idResep)
	if err != nil {
		// Kirim pesan error dari database (misalnya stok tidak cukup)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Kirim response sukses
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": fmt.Sprintf("Resep ID %s berhasil diproses.", idResep)})
}

// Handler untuk laporan penjualan harian
func getLaporanPenjualanHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query("SELECT * FROM view_laporan_penjualan_harian")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var laporans []LaporanPenjualan
	for rows.Next() {
		var laporan LaporanPenjualan
		if err := rows.Scan(&laporan.TanggalPenjualan, &laporan.JumlahTransaksi, &laporan.TotalPenjualan); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		laporans = append(laporans, laporan)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(laporans)
}

// Handler untuk membuat obat baru
func createObatHandler(w http.ResponseWriter, r *http.Request) {
	var obat Obat
	decoder := json.NewDecoder(r.Body)
	// Tambahkan pengaturan agar decoder lebih ketat
	decoder.DisallowUnknownFields()

	err := decoder.Decode(&obat)
	if err != nil {
		// Cetak detail error ke terminal server Go
		log.Printf("ERROR: Gagal decode JSON body: %v", err)
		// Kirim response error 400 ke Flutter
		http.Error(w, "Request body tidak valid: "+err.Error(), http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Jalankan query INSERT
	sqlStatement := `INSERT INTO obat (nama_obat, jenis, harga, stok, expired_date) VALUES (?, ?, ?, ?, ?)`
	_, err = db.Exec(sqlStatement, obat.NamaObat, obat.Jenis, obat.Harga, obat.Stok, obat.ExpiredDate)
	if err != nil {
		log.Printf("ERROR: Gagal insert ke database: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"message": "Obat berhasil ditambahkan"})
}

// Handler untuk memperbarui data obat
func updateObatHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]

	var obat Obat
	if err := json.NewDecoder(r.Body).Decode(&obat); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	sqlStatement := `UPDATE obat SET nama_obat=?, jenis=?, harga=?, stok=?, expired_date=? WHERE id_obat=?`
	_, err := db.Exec(sqlStatement, obat.NamaObat, obat.Jenis, obat.Harga, obat.Stok, obat.ExpiredDate, id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Obat berhasil diperbarui"})
}

// Handler untuk menghapus obat
func deleteObatHandler(w http.ResponseWriter, r *http.Request) {
	// Ambil ID dari URL
	vars := mux.Vars(r)
	id := vars["id"]

	// Jalankan query DELETE
	_, err := db.Exec("DELETE FROM obat WHERE id_obat = ?", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"message": "Obat berhasil dihapus"})
}

// Handler untuk membuat transaksi baru
func createTransaksiHandler(w http.ResponseWriter, r *http.Request) {
	// Decode payload dari Flutter
	var payload TransaksiPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	// Memulai transaksi database
	tx, err := db.Begin()
	if err != nil {
		http.Error(w, "Gagal memulai transaksi", http.StatusInternalServerError)
		return
	}
	// defer akan memastikan Rollback dijalankan jika ada error di tengah jalan
	defer tx.Rollback()

	// 1. Insert ke tabel master 'transaksi'
	res, err := tx.Exec("INSERT INTO transaksi (tanggal, id_pelanggan, total_harga) VALUES (NOW(), ?, ?)", payload.IDPelanggan, payload.TotalHarga)
	if err != nil {
		http.Error(w, "Gagal menyimpan transaksi utama", http.StatusInternalServerError)
		return
	}

	// Ambil ID dari transaksi yang baru saja dibuat
	idTransaksi, err := res.LastInsertId()
	if err != nil {
		http.Error(w, "Gagal mendapatkan ID transaksi", http.StatusInternalServerError)
		return
	}

	// 2. Siapkan statement untuk insert ke 'detail_transaksi'
	stmt, err := tx.Prepare("INSERT INTO detail_transaksi (id_transaksi, id_obat, jumlah, harga_satuan) VALUES (?, ?, ?, ?)")
	if err != nil {
		http.Error(w, "Gagal menyiapkan statement detail", http.StatusInternalServerError)
		return
	}
	defer stmt.Close()

	// 3. Looping untuk setiap item di keranjang dan insert ke 'detail_transaksi'
	for _, item := range payload.Items {
		if _, err := stmt.Exec(idTransaksi, item.IDObat, item.Jumlah, item.Harga); err != nil {
			http.Error(w, "Gagal menyimpan detail item transaksi", http.StatusInternalServerError)
			return
		}
		// Trigger di database akan otomatis mengurangi stok dan menghitung subtotal
	}

	// 4. Jika semua berhasil, commit transaksi
	if err := tx.Commit(); err != nil {
		http.Error(w, "Gagal menyelesaikan transaksi (commit)", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"message":      "Transaksi berhasil dibuat",
		"id_transaksi": idTransaksi,
	})
}
