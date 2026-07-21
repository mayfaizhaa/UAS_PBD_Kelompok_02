DROP DATABASE IF EXISTS kasir_minimarket;
CREATE DATABASE kasir_minimarket;
USE kasir_minimarket;

CREATE TABLE kategori (
    kategori_id   INT AUTO_INCREMENT PRIMARY KEY,
    nama_kategori VARCHAR(50) NOT NULL
);

CREATE TABLE produk (
    produk_id     INT AUTO_INCREMENT PRIMARY KEY,
    kategori_id   INT NOT NULL,
    nama_produk   VARCHAR(100) NOT NULL,
    harga         DECIMAL(12,2) NOT NULL,
    stok          INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_produk_kategori
        FOREIGN KEY (kategori_id) REFERENCES kategori(kategori_id)
);

CREATE TABLE pelanggan (
    pelanggan_id   INT AUTO_INCREMENT PRIMARY KEY,
    nama_pelanggan VARCHAR(100) NOT NULL,
    no_hp          VARCHAR(20),
    poin           INT DEFAULT 0
);

CREATE TABLE diskon (
    diskon_id      INT AUTO_INCREMENT PRIMARY KEY,
    min_qty        INT NOT NULL,
    persen_diskon  DECIMAL(5,2) NOT NULL,
    keterangan     VARCHAR(100)
);

CREATE TABLE transaksi (
    transaksi_id       INT AUTO_INCREMENT PRIMARY KEY,
    pelanggan_id        INT NULL,
    tanggal_transaksi   DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_belanja       DECIMAL(12,2) DEFAULT 0,
    total_diskon        DECIMAL(12,2) DEFAULT 0,
    total_bayar          DECIMAL(12,2) DEFAULT 0,
    status               VARCHAR(20) DEFAULT 'PROSES',
    CONSTRAINT fk_transaksi_pelanggan
        FOREIGN KEY (pelanggan_id) REFERENCES pelanggan(pelanggan_id)
);

CREATE TABLE detail_transaksi (
    detail_id     INT AUTO_INCREMENT PRIMARY KEY,
    transaksi_id  INT NOT NULL,
    produk_id     INT NOT NULL,
    qty           INT NOT NULL,
    harga_satuan  DECIMAL(12,2) NOT NULL,
    subtotal      DECIMAL(12,2) NOT NULL,
    CONSTRAINT fk_detail_transaksi
        FOREIGN KEY (transaksi_id) REFERENCES transaksi(transaksi_id),
    CONSTRAINT fk_detail_produk
        FOREIGN KEY (produk_id) REFERENCES produk(produk_id)
);

CREATE TABLE audit_log (
    log_id      INT AUTO_INCREMENT PRIMARY KEY,
    nama_tabel  VARCHAR(50),
    aksi        VARCHAR(20),
    id_data     INT,
    data_lama   TEXT,
    data_baru   TEXT,
    waktu       DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE laporan_harian (
    laporan_id         INT AUTO_INCREMENT PRIMARY KEY,
    tanggal            DATE,
    produk_id          INT,
    nama_produk        VARCHAR(100),
    total_qty_terjual  INT,
    total_pendapatan   DECIMAL(12,2),
    dibuat_pada        DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Mempercepat pencarian produk oleh kasir saat mengetik nama barang
CREATE INDEX idx_nama_produk ON produk(nama_produk);
-- Mempercepat filter laporan penjualan per tanggal/periode
CREATE INDEX idx_tanggal_transaksi ON transaksi(tanggal_transaksi);
-- Mempercepat JOIN & rekap penjualan per produk pada laporan
CREATE INDEX idx_produk_detail ON detail_transaksi(produk_id);

INSERT INTO kategori (nama_kategori) VALUES
('Sembako'), ('Minuman'), ('Snack'), ('Kebersihan'), ('Perawatan Diri');

INSERT INTO produk (kategori_id, nama_produk, harga, stok) VALUES
(1, 'Beras 5kg', 65000, 50),
(1, 'Minyak Goreng 1L', 18000, 40),
(1, 'Gula Pasir 1kg', 15000, 60),
(1, 'Telur 1kg', 28000, 30),
(2, 'Air Mineral 600ml', 4000, 100),
(2, 'Teh Botol 350ml', 5000, 80),
(2, 'Kopi Sachet', 2000, 120),
(2, 'Susu UHT 250ml', 6000, 70),
(3, 'Keripik Kentang', 12000, 45),
(3, 'Biskuit Coklat', 9000, 55),
(3, 'Wafer Vanila', 7000, 50),
(4, 'Sabun Cuci Piring', 8500, 35),
(4, 'Deterjen 800g', 17000, 25),
(5, 'Sabun Mandi', 5500, 40),
(5, 'Shampo Sachet', 1500, 150);

INSERT INTO pelanggan (nama_pelanggan, no_hp, poin) VALUES
('Andi Saputra', '081234567801', 0),
('Budi Santoso', '081234567802', 0),
('Citra Ayu', '081234567803', 0),
('Dewi Lestari', '081234567804', 0),
('Eko Prasetyo', '081234567805', 0);

INSERT INTO diskon (min_qty, persen_diskon, keterangan) VALUES
(5, 5.00, 'Diskon pembelian minimal 5 item'),
(10, 10.00, 'Diskon pembelian minimal 10 item'),
(20, 15.00, 'Diskon pembelian minimal 20 item');

-- Verifikasi cepat
SELECT COUNT(*) AS jumlah_produk FROM produk;
SELECT COUNT(*) AS jumlah_pelanggan FROM pelanggan;
SHOW INDEX FROM produk;
SHOW INDEX FROM transaksi;
