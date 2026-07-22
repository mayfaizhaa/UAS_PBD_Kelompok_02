USE kasir_minimarket;

DELIMITER $$

CREATE TRIGGER trg_validasi_stok
BEFORE INSERT ON detail_transaksi
FOR EACH ROW
BEGIN
    DECLARE v_stok INT;
    SELECT stok INTO v_stok FROM produk WHERE produk_id = NEW.produk_id;

    IF v_stok IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Produk tidak ditemukan';
    ELSEIF v_stok < NEW.qty THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok tidak mencukupi untuk transaksi ini';
    END IF;
END$$

CREATE TRIGGER trg_kurangi_stok
AFTER INSERT ON detail_transaksi
FOR EACH ROW
BEGIN
    UPDATE produk SET stok = stok - NEW.qty WHERE produk_id = NEW.produk_id;
END$$

CREATE TRIGGER trg_audit_update_produk
AFTER UPDATE ON produk
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (nama_tabel, aksi, id_data, data_lama, data_baru, user_db)
    VALUES (
        'produk', 'UPDATE', OLD.produk_id,
        CONCAT('nama:', OLD.nama_produk, ', harga:', OLD.harga, ', stok:', OLD.stok),
        CONCAT('nama:', NEW.nama_produk, ', harga:', NEW.harga, ', stok:', NEW.stok),
        USER()
    );
END$$

CREATE TRIGGER trg_audit_insert_transaksi
AFTER INSERT ON transaksi
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (nama_tabel, aksi, id_data, data_baru, user_db)
    VALUES (
        'transaksi', 'INSERT', NEW.transaksi_id,
        CONCAT('pelanggan_id:', IFNULL(NEW.pelanggan_id, 0), ', status:', NEW.status),
        USER()
    );
END$$

DELIMITER ;