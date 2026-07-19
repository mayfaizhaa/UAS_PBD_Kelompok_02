# Sistem Basis Data Kasir Minimarket

Proyek ini dibuat untuk memenuhi Tugas Evaluasi Akhir Semester (EAS) Pemrograman Basis Data. Sistem ini mengimplementasikan basis data relasional untuk operasional kasir minimarket menggunakan **MySQL 8.0+** dengan integrasi fitur database tingkat lanjut seperti *Stored Procedure, Function, Trigger, Cursor, Exception Handling, Transaction Control, Indexing,* dan *Audit Logging*.

## Struktur File Proyek

Proyek ini dibagi menjadi 4 file SQL utama yang dikerjakan secara kolaboratif sesuai pembagian peran (PIC):

| File | Deskripsi / Isi | PIC |
| --- | --- | --- |
| `01_tabel_dan_index_mayfaizha.sql` | Pembuatan database `kasir_minimarket`, 8 tabel utama, relasi PK/FK, 3 index, dan pengisian data dummy. | **Mayfaizha** |
| `02_function_dan_procedure_sittirahma.sql` | Pembuatan 2 Function kalkulasi dan 4 Stored Procedure (termasuk cursor untuk rekapitulasi laporan harian). | **Sitti Rahma** |
| `03_trigger_dan_transaction_azizah.sql` | Pembuatan 4 Trigger (validasi stok, auto-update stok, audit log) dan contoh kontrol transaksi manual (COMMIT/SAVEPOINT). | **Azizah** |
| `04_testing_dan_demo_mahruf.sql` | Skenario demonstrasi alur transaksi kasir (pelanggan member & non-member), pengujian audit log, laporan harian, dan query verifikasi data. | **Muhammad Mahruf** |

---

## Skema Tabel Basis Data

Terdapat 8 tabel utama yang saling berelasi:

| No | Tabel | Fungsi |
| --- | --- | --- |
| 1 | `kategori` | Menyimpan kategori produk |
| 2 | `produk` | Menyimpan daftar produk, harga, dan stok |
| 3 | `pelanggan` | Menyimpan data member dan poin belanja |
| 4 | `diskon` | Aturan minimal qty untuk mendapat potongan harga |
| 5 | `transaksi` | Header transaksi (total belanja, diskon, bayar, status) |
| 6 | `detail_transaksi` | Item produk yang dibeli per transaksi beserta subtotal |
| 7 | `audit_log` | Mencatat log perubahan insert/update pada data produk dan transaksi |
| 8 | `laporan_harian` | Rekapitulasi penjualan per produk per hari |

---

## Fitur yang Diimplementasikan

### Function

| Nama | Keterangan |
| --- | --- |
| `fn_hitung_diskon(qty, harga)` | Menghitung nilai diskon rupiah berdasarkan jumlah qty dan harga satuan |
| `fn_total_terjual(produk_id)` | Mengembalikan total qty terjual dari seluruh transaksi untuk satu produk |

### Stored Procedure

| Nama | Keterangan |
| --- | --- |
| `sp_tambah_transaksi` | Membuat header transaksi baru, mendukung pelanggan member maupun non-member |
| `sp_tambah_detail_transaksi` | Menambahkan item produk ke transaksi, validasi stok, kalkulasi diskon, dan update total |
| `sp_selesaikan_transaksi` | Memproses pembayaran, memvalidasi jumlah bayar, dan menghitung uang kembalian |
| `sp_laporan_penjualan_harian` | Menggunakan **cursor** untuk merekap penjualan per produk pada tanggal tertentu |

### Trigger

| Nama | Event | Keterangan |
| --- | --- | --- |
| `trg_validasi_stok` | `BEFORE INSERT` | Memblokir transaksi jika stok produk tidak mencukupi (via SIGNAL) |
| `trg_kurangi_stok` | `AFTER INSERT` | Mengurangi stok produk secara otomatis setelah berhasil ditambahkan ke transaksi |
| `trg_audit_update_produk` | `AFTER UPDATE` | Mencatat perubahan data produk (harga/stok) ke tabel `audit_log` |
| `trg_audit_insert_transaksi` | `AFTER INSERT` | Mencatat setiap transaksi baru yang masuk ke tabel `audit_log` |

### Indexing

| Nama Index | Kolom | Tujuan |
| --- | --- | --- |
| `idx_nama_produk` | `produk.nama_produk` | Mempercepat pencarian produk berdasarkan nama |
| `idx_tanggal_transaksi` | `transaksi.tanggal_transaksi` | Mempercepat filter laporan berdasarkan tanggal |
| `idx_produk_detail` | `detail_transaksi.produk_id` | Mempercepat JOIN untuk laporan rekap penjualan per produk |

---

## Aturan Diskon

Diskon dihitung otomatis oleh `fn_hitung_diskon()` berdasarkan total qty per item:

| Minimal Qty | Diskon |
| --- | --- |
| 5 item | 5% |
| 10 item | 10% |
| 20 item | 15% |

---

## Alur Proses Transaksi

```
1. sp_tambah_transaksi()         → Membuat header transaksi baru
2. sp_tambah_detail_transaksi()  → Menambahkan item produk
      ├── fn_hitung_diskon()       dipanggil untuk kalkulasi diskon
      ├── trg_validasi_stok        berjalan sebelum insert (blokir jika stok kurang)
      └── trg_kurangi_stok         berjalan setelah insert (kurangi stok otomatis)
3. sp_selesaikan_transaksi()     → Memproses pembayaran dan menghitung kembalian
4. trg_audit_insert_transaksi    → Mencatat log transaksi ke audit_log
```

---

## Petunjuk Menjalankan Script SQL

Eksekusi file secara berurutan agar tidak terjadi error referensi objek yang belum dibuat:

```
1. 01_tabel_dan_index_mayfaizha.sql        → Buat database, tabel, index, data dummy
2. 02_function_dan_procedure_sittirahma.sql → Daftarkan function dan stored procedure
3. 03_trigger_dan_transaction_azizah.sql   → Aktifkan trigger dan jalankan transaction control
4. 04_testing_dan_demo_mahruf.sql          → Simulasikan transaksi dan verifikasi hasil
```

---

## Anggota Kelompok

| Nama | PIC / Bagian |
| --- | --- |
| Mayfaizha | Struktur database, tabel, indexing, dan data dummy |
| Sitti Rahma | Function dan Stored Procedure |
| Azizah | Trigger dan Transaction Control |
| Muhammad Mahruf | Testing, demo transaksi, dan verifikasi hasil |
