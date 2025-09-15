<?php
header('Content-Type: application/json');

// Koneksi ke database
$host = 'localhost';
$user = 'root';
$pass = ''; 
$db   = 'resto_db';

$koneksi = new mysqli($host, $user, $pass, $db);

if ($koneksi->connect_error) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Koneksi gagal: ' . $koneksi->connect_error
    ]);
    exit;
}

$id = isset($_GET['id']) ? intval($_GET['id']) : 0;

if ($id <= 0) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Parameter ID tidak valid'
    ]);
    exit;
}

// ✅ pakai prepared statement biar aman
$stmt = $koneksi->prepare("SELECT nama, email, no_hp, foto FROM users WHERE id=?");
$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result();

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();

    // Tambahkan base URL ke foto
    if (!empty($user['foto'])) {
        $user['foto'] = "http://192.168.1.6/test_application/uploads/" . $user['foto'];
    }

    echo json_encode([
        'status' => 'success',
        'data' => $user
    ]);
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'User tidak ditemukan'
    ]);
}

$stmt->close();
$koneksi->close();
?>
