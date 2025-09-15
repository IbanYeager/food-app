-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Waktu pembuatan: 15 Sep 2025 pada 08.39
-- Versi server: 10.4.32-MariaDB
-- Versi PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `resto_db`
--

-- --------------------------------------------------------

--
-- Struktur dari tabel `menus`
--

DROP TABLE IF EXISTS `menus`;
CREATE TABLE `menus` (
  `id` int(11) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `harga` int(11) NOT NULL,
  `gambar` varchar(100) NOT NULL,
  `deskripsi` text NOT NULL,
  `latitude` decimal(10,7) NOT NULL,
  `longitude` decimal(10,7) NOT NULL,
  `kategori` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `menus`
--

INSERT INTO `menus` (`id`, `nama`, `harga`, `gambar`, `deskripsi`, `latitude`, `longitude`, `kategori`) VALUES
(1, 'Burger', 25000, 'Burger.jpg', 'Burger lezat dengan daging sapi premium, sayuran segar, dan saus spesial.', -6.9175000, 107.6046000, 'Makanan'),
(2, 'Pizza', 40000, 'Pizza.jpg', 'Pizza dengan topping keju mozzarella melimpah dan saus tomat asli.', -6.9147000, 107.6098000, 'Makanan'),
(3, 'Drink', 15000, 'Drink.jpg', 'Aneka minuman segar untuk menemani santapan Anda.', -6.9050000, 107.6131000, 'Minuman'),
(4, 'Sandwich', 30000, 'Sandwich.jpg', 'Sandwich sehat dengan roti gandum dan sayuran organik.', -6.9260000, 107.6340000, 'Makanan'),
(5, 'Fried Chicken', 35000, 'FriedChicken.jpg', 'Ayam goreng crispy dengan bumbu rahasia khas resto.', -6.9272000, 107.6046000, 'Makanan'),
(6, 'Spaghetti', 32000, 'Spaghetti.jpg', 'Spaghetti Italia autentik dengan saus bolognese spesial.', -6.9210000, 107.6150000, 'Makanan'),
(7, 'Sushi', 45000, 'Sushi.jpg', 'Sushi segar dengan ikan pilihan dan nasi Jepang berkualitas.', -6.9225000, 107.6070000, 'Makanan'),
(8, 'Ramen', 38000, 'Ramen.jpg', 'Ramen kuah kaldu gurih dengan topping telur setengah matang.', -6.9105000, 107.6111000, 'Makanan'),
(9, 'Steak', 60000, 'Steak.jpg', 'Steak daging premium dengan saus lada hitam.', -6.9300000, 107.6200000, 'Makanan'),
(10, 'Hotdog', 20000, 'Hotdog.jpg', 'Hotdog jumbo dengan sosis sapi dan saus mayonaise.', -6.9188000, 107.6305000, 'Makanan'),
(11, 'Nasi Goreng', 28000, 'NasiGoreng.jpg', 'Nasi goreng khas Bandung dengan bumbu rempah pilihan.', -6.9190000, 107.6221000, 'Makanan'),
(12, 'Mie Goreng', 27000, 'MieGoreng.jpg', 'Mie goreng spesial dengan topping ayam dan sayuran.', -6.9250000, 107.6100000, 'Makanan'),
(13, 'Ice Cream', 18000, 'IceCream.jpg', 'Ice cream lembut dengan berbagai pilihan rasa manis.', -6.9070000, 107.6210000, 'Dessert'),
(14, 'Milkshake', 22000, 'Milkshake.jpg', 'Milkshake segar dengan berbagai rasa favorit anak muda.', -6.9155000, 107.6255000, 'Minuman'),
(15, 'French Fries', 15000, 'KentangGoreng.jpg', 'Kentang goreng renyah dengan taburan garam halus.', -6.9235000, 107.6177000, 'Makanan'),
(16, 'Donut', 12000, 'Donut.jpg', 'Donat manis empuk dengan berbagai pilihan topping.', -6.9110000, 107.6099000, 'Dessert'),
(17, 'Taco', 33000, 'Taco.jpg', 'Taco ala Meksiko dengan daging sapi cincang dan keju.', -6.9200000, 107.6185000, 'Makanan'),
(18, 'Burrito', 35000, 'Burrito.jpg', 'Burrito isi daging sapi, kacang merah, dan sayuran.', -6.9165000, 107.6280000, 'Makanan'),
(19, 'Kebab', 30000, 'Kebab.jpg', 'Kebab khas Timur Tengah dengan daging sapi panggang.', -6.9130000, 107.6160000, 'Makanan'),
(20, 'Salad', 25000, 'Salad.jpg', 'Salad segar dengan sayuran organik dan dressing spesial.', -6.9240000, 107.6088000, 'Makanan');

-- --------------------------------------------------------

--
-- Struktur dari tabel `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `no_hp` varchar(20) DEFAULT NULL,
  `foto` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data untuk tabel `users`
--

INSERT INTO `users` (`id`, `nama`, `email`, `password`, `no_hp`, `foto`) VALUES
(2, 'Admin Booyah', 'admin@gmail.com', '$2y$10$sApso3.foz2hOVn70w34QOmx/2liINUkqbWhHVkYOQDnhf8NdhvjK', '081234567890', 'uploads/user_2_1757910856.jpg');

--
-- Indexes for dumped tables
--

--
-- Indeks untuk tabel `menus`
--
ALTER TABLE `menus`
  ADD PRIMARY KEY (`id`);

--
-- Indeks untuk tabel `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT untuk tabel yang dibuang
--

--
-- AUTO_INCREMENT untuk tabel `menus`
--
ALTER TABLE `menus`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT untuk tabel `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
