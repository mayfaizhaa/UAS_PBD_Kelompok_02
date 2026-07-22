-- =====================================================================
-- File: 04_testing_dan_demo_mahruf.sql
-- PIC: Muhammad Mahruf
-- Bagian: Simulasi Transaksi dan Verifikasi Hasil
-- =====================================================================

USE kasir_minimarket;

-- =====================================================================
-- 7. SIMULASI TRANSAKSI & PENGUJIAN
-- =====================================================================

-- Skenario 1: Transaksi Member (COMMIT)
SET @trx1 = 0;
CALL sp_tambah_transaksi(1, @trx1);
CALL sp_tambah_detail_transaksi(@trx1, 1, 2);
CALL sp_tambah_detail_transaksi(@trx1, 5, 6);
SET @kembalian1 = 0;
CALL sp_selesaikan_transaksi(@trx1, 200000, @kembalian1);
SELECT @trx1 AS transaksi_id, @kembalian1 AS kembalian;

-- Skenario 2: Transaksi Non-Member (COMMIT)
SET @trx2 = 0;
CALL sp_tambah_transaksi(NULL, @trx2);
CALL sp_tambah_detail_transaksi(@trx2, 9, 10);
SET @kembalian2 = 0;
CALL sp_selesaikan_transaksi(@trx2, 150000, @kembalian2);
SELECT @trx2 AS transaksi_id, @kembalian2 AS kembalian;

-- Skenario 3: Transaksi Manual (SAVEPOINT & ROLLBACK)
START TRANSACTION;
SAVEPOINT sp_batal;
INSERT INTO transaksi (pelanggan_id, status) VALUES (3, 'PROSES');
ROLLBACK TO SAVEPOINT sp_batal;
COMMIT;

-- Skenario 4: Update Harga (Trigger Audit Log)
UPDATE produk SET harga = 66000 WHERE produk_id = 1;
SELECT * FROM audit_log WHERE nama_tabel = 'produk';

-- Skenario 5: Laporan Penjualan Harian (CURSOR)
CALL sp_laporan_penjualan_harian(CURDATE());

-- =====================================================================
-- 9. VERIFIKASI HASIL AKHIR
-- =====================================================================
SELECT * FROM produk;
SELECT * FROM transaksi;
SELECT * FROM detail_transaksi;
SELECT * FROM audit_log ORDER BY waktu DESC;
SELECT * FROM laporan_harian;
