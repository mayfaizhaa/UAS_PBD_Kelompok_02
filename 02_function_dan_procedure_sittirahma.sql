-- =====================================================================
-- BAGIAN 2 dari 4 — SISTEM BASIS DATA KASIR MINIMARKET
-- PIC: Sitti Rahma
-- Isi: FUNCTION (minimal 2) dan STORED PROCEDURE (minimal 3),
--      termasuk implementasi CURSOR pada laporan penjualan harian
-- Jalankan SETELAH file 01_tabel_dan_index_mayfaizha.sql
-- =====================================================================

USE kasir_minimarket;

-- =====================================================================
-- 1. FUNCTION
-- =====================================================================
-- CATATAN: jika muncul error "This function has none of DETERMINISTIC..."
-- saat membuat function di bawah, jalankan sekali saja sebelumnya:
-- SET GLOBAL log_bin_trust_function_creators = 1;

DELIMITER $$

-- Function 1: menghitung nilai diskon berdasarkan qty & harga
CREATE FUNCTION fn_hitung_diskon(p_qty INT, p_harga DECIMAL(12,2))
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
    DECLARE v_persen DECIMAL(5,2) DEFAULT 0;
    DECLARE v_nilai_diskon DECIMAL(12,2) DEFAULT 0;

    SELECT persen_diskon INTO v_persen
    FROM diskon
    WHERE min_qty <= p_qty
    ORDER BY min_qty DESC
    LIMIT 1;

    IF v_persen IS NULL THEN
        SET v_persen = 0;
    END IF;

    SET v_nilai_diskon = (p_harga * p_qty) * (v_persen / 100);
    RETURN v_nilai_diskon;
END$$

-- Function 2: menghitung total qty terjual untuk sebuah produk
CREATE FUNCTION fn_total_terjual(p_produk_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_total INT DEFAULT 0;
    SELECT IFNULL(SUM(qty), 0) INTO v_total
    FROM detail_transaksi
    WHERE produk_id = p_produk_id;
    RETURN v_total;
END$$

DELIMITER ;

-- =====================================================================
-- 2. STORED PROCEDURE
-- =====================================================================

DELIMITER $$

-- Procedure 1: membuka transaksi baru (header)
CREATE PROCEDURE sp_tambah_transaksi(
    IN  p_pelanggan_id INT,
    OUT p_transaksi_id INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    INSERT INTO transaksi (pelanggan_id, status)
    VALUES (p_pelanggan_id, 'PROSES');
    SET p_transaksi_id = LAST_INSERT_ID();
    COMMIT;
END$$

-- Procedure 2: menambah item ke detail transaksi
CREATE PROCEDURE sp_tambah_detail_transaksi(
    IN p_transaksi_id INT,
    IN p_produk_id    INT,
    IN p_qty          INT
)
BEGIN
    DECLARE v_harga    DECIMAL(12,2);
    DECLARE v_diskon   DECIMAL(12,2);
    DECLARE v_subtotal DECIMAL(12,2);
    DECLARE v_produk_ada INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK TO SAVEPOINT sp_detail;
        RESIGNAL;
    END;

    START TRANSACTION;
    SAVEPOINT sp_detail;

    SELECT COUNT(*) INTO v_produk_ada FROM produk WHERE produk_id = p_produk_id;
    IF v_produk_ada = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Produk tidak ditemukan di database';
    END IF;

    SELECT harga INTO v_harga FROM produk WHERE produk_id = p_produk_id;
    SET v_diskon   = fn_hitung_diskon(p_qty, v_harga);
    SET v_subtotal = (v_harga * p_qty) - v_diskon;

    -- Trigger trg_validasi_stok & trg_kurangi_stok (dibuat oleh Azizah) berjalan di sini
    INSERT INTO detail_transaksi (transaksi_id, produk_id, qty, harga_satuan, subtotal)
    VALUES (p_transaksi_id, p_produk_id, p_qty, v_harga, v_subtotal);

    UPDATE transaksi
    SET total_belanja = total_belanja + (v_harga * p_qty),
        total_diskon  = total_diskon + v_diskon,
        total_bayar   = total_bayar + v_subtotal
    WHERE transaksi_id = p_transaksi_id;

    COMMIT;
END$$

-- Procedure 3: menyelesaikan transaksi (pembayaran & kembalian)
CREATE PROCEDURE sp_selesaikan_transaksi(
    IN  p_transaksi_id INT,
    IN  p_bayar        DECIMAL(12,2),
    OUT p_kembalian    DECIMAL(12,2)
)
BEGIN
    DECLARE v_total_bayar DECIMAL(12,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
    SAVEPOINT sp_selesai;

    SELECT total_bayar INTO v_total_bayar
    FROM transaksi WHERE transaksi_id = p_transaksi_id;

    IF p_bayar < v_total_bayar THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pembayaran tidak mencukupi total transaksi';
    END IF;

    UPDATE transaksi
    SET status = 'SELESAI'
    WHERE transaksi_id = p_transaksi_id;

    SET p_kembalian = p_bayar - v_total_bayar;
    COMMIT;
END$$

-- Procedure 4: laporan penjualan harian menggunakan CURSOR
CREATE PROCEDURE sp_laporan_penjualan_harian(
    IN p_tanggal DATE
)
BEGIN
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_produk_id INT;
    DECLARE v_nama_produk VARCHAR(100);
    DECLARE v_total_qty INT;
    DECLARE v_total_pendapatan DECIMAL(12,2);

    DECLARE cur_laporan CURSOR FOR
        SELECT dt.produk_id, p.nama_produk,
               SUM(dt.qty) AS total_qty,
               SUM(dt.subtotal) AS total_pendapatan
        FROM detail_transaksi dt
        JOIN transaksi t   ON dt.transaksi_id = t.transaksi_id
        JOIN produk p      ON dt.produk_id = p.produk_id
        WHERE DATE(t.tanggal_transaksi) = p_tanggal
        GROUP BY dt.produk_id, p.nama_produk;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    DELETE FROM laporan_harian WHERE tanggal = p_tanggal;

    OPEN cur_laporan;

    baca_loop: LOOP
        FETCH cur_laporan INTO v_produk_id, v_nama_produk, v_total_qty, v_total_pendapatan;
        IF v_done = 1 THEN
            LEAVE baca_loop;
        END IF;

        INSERT INTO laporan_harian (tanggal, produk_id, nama_produk, total_qty_terjual, total_pendapatan)
        VALUES (p_tanggal, v_produk_id, v_nama_produk, v_total_qty, v_total_pendapatan);
    END LOOP;

    CLOSE cur_laporan;

    SELECT * FROM laporan_harian WHERE tanggal = p_tanggal;
END$$

DELIMITER ;

-- Uji cepat function (aman dijalankan meski data transaksi belum ada)
SELECT fn_hitung_diskon(10, 10000) AS contoh_diskon;