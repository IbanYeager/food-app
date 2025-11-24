<?php
// ===== api/get_user.php (DENGAN LOGIKA ROLE) =====
header('Content-Type: application/json');
include "config.php";

$id = isset($_GET['id']) ? intval($_GET['id']) : 0;
$role = isset($_GET['role']) ? $_GET['role'] : 'customer'; // 💡 Ambil parameter Role

if ($id <= 0) {
    echo json_encode(['status' => 'error', 'message' => 'ID tidak valid']);
    exit;
}

// Tentukan tabel berdasarkan role
$table = ($role === 'courier') ? 'couriers' : 'users';

// Siapkan query
$stmt = $conn->prepare("SELECT * FROM $table WHERE id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result();

if ($result && $result->num_rows > 0) {
    $data = $result->fetch_assoc();

    // Format URL Foto
    if (!empty($data['foto'])) {
        $data['foto'] = "http://192.168.1.6/test_application/uploads/" . $data['foto'];
    }

    // Hapus password agar aman
    unset($data['password']);

    echo json_encode([
        'status' => 'success',
        'data' => $data
    ]);
} else {
    echo json_encode([
        'status' => 'error',
        'message' => 'User tidak ditemukan di tabel ' . $table
    ]);
}

$stmt->close();
$conn->close();
?>