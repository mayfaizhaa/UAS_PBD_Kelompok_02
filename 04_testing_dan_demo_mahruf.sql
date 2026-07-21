-- File: 04_testing_dan_demo_mahruf.sql
-- PIC: Muhammad Mahruf

USE kasir_minimarket;

-- ==========================================
-- SKENARIO TRANSAKSI
-- ==========================================

-- Transaksi 1 (Pelanggan Member)
SET @trx1 = 0;
CALL sp_tambah_transaksi(1, @trx1);
CALL sp_tambah_detail_transaksi(@trx1, 1, 2);   -- Beras 5kg x2
CALL sp_tambah_detail_transaksi(@trx1, 5, 6);   -- Air Mineral x6
SET @kembalian1 = 0;
CALL sp_selesaikan_transaksi(@trx1, 200000, @kembalian1);
SELECT @trx1 AS transaksi_id, @kembalian1 AS kembalian;

-- Transaksi 2 (Pelanggan Non-Member)
SET @trx2 = 0;
CALL sp_tambah_transaksi(NULL, @trx2);
CALL sp_tambah_detail_transaksi(@trx2, 9, 10);  -- Keripik Kentang x10
SET @kembalian2 = 0;
CALL sp_selesaikan_transaksi(@trx2, 150000, @kembalian2);
SELECT @trx2 AS transaksi_id, @kembalian2 AS kembalian;

-- ==========================================
-- PENGUJIAN TRIGGER & CURSOR
-- ==========================================

-- Update harga produk untuk memicu trigger audit log
UPDATE produk SET harga = 66000 WHERE produk_id = 1;

-- Menjalankan laporan harian (CURSOR)
CALL sp_laporan_penjualan_harian(CURDATE());

-- ==========================================
-- CEK HASIL AKHIR
-- ==========================================
SELECT * FROM produk;
SELECT * FROM transaksi;
SELECT * FROM detail_transaksi;
SELECT * FROM audit_log ORDER BY waktu DESC;
SELECT * FROM laporan_harian;
