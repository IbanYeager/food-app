<?php
// Hubungkan ke database Anda (ganti dengan koneksi Anda)
$host = "localhost";
$user = "root";
$pass = "";
$db = "resto_db"; // Ganti nama DB

$koneksi = new mysqli($host, $user, $pass, $db);

if ($koneksi->connect_error) {
    die("Koneksi gagal: " . $koneksi->connect_error);
}

// 💡 PERBAIKAN 1: Ganti nama tabel 'pesanan' menjadi 'orders'
// 💡 PERBAIKAN 2: Ganti 'status_pesanan = 'baru'' menjadi 'status = 'Pending''
// 💡 PERBAIKAN 3: Ganti 'waktu_pesanan' menjadi 'date' (sesuai file orders.php)
$sql = "SELECT * FROM orders WHERE status = 'Pending' ORDER BY date DESC";
$result = $koneksi->query($sql);

$pesanan_baru = array();

if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        // Masukkan data ke array
        $pesanan_baru[] = $row;
    }
}

// 2. Kembalikan data dalam format JSON
// Ini SANGAT PENTING agar bisa dibaca JavaScript
header('Content-Type: application/json');
echo json_encode($pesanan_baru);

$koneksi->close();
?>