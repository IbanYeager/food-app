<?php
header("Content-Type: application/json; charset=UTF-8");
error_reporting(0); // sembunyikan warning/notice agar tidak merusak JSON
ini_set('display_errors', 0);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        "success" => false,
        "message" => "Metode tidak valid"
    ]);
    exit;
}

include "config.php";

$identifier = $_POST['email'] ?? '';  // bisa email atau no_hp
$password   = $_POST['password'] ?? '';

if (empty($identifier) || empty($password)) {
    echo json_encode([
        "success" => false,
        "message" => "Data tidak lengkap"
    ]);
    exit;
}

$stmt = $conn->prepare("SELECT * FROM users WHERE email = ? OR no_hp = ? LIMIT 1");
$stmt->bind_param("ss", $identifier, $identifier);
$stmt->execute();
$result = $stmt->get_result();

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();

    // ...
if (password_verify($password, $user['password'])) {

    // 💡 PERBAIKAN: URL disamakan dengan get_user.php dan update_user.php
    $foto_url = null;
    if (!empty($user['foto'])) {
        // Hapus '/api/' dan gunakan huruf kecil 'test_application'
        $foto_url = "http://192.168.1.7/test_application/uploads/" . $user['foto'];
    }

    echo json_encode([
        "success" => true,
        "message" => "Login berhasil",
        "data" => [
            "id"    => $user['id'],
            "nama"  => $user['nama'],
            "email" => $user['email'],
            "no_hp" => $user['no_hp'],
            "foto"  => $foto_url // <-- KIRIM URL LENGKAPNYA
        ]
    ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Password salah"
        ]);
    }
} else {
    echo json_encode([
        "success" => false,
        "message" => "Email / No HP tidak ditemukan"
    ]);
}

$stmt->close();
$conn->close();