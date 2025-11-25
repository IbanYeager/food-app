<?php
// ===== api/login_unified.php =====
header("Content-Type: application/json; charset=UTF-8");
error_reporting(0); // Sembunyikan warning
ini_set('display_errors', 0);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["success" => false, "message" => "Metode tidak valid"]);
    exit;
}

include "config.php"; // $conn

$identifier = $_POST['identifier'] ?? ''; // Bisa email atau no_hp
$password = $_POST['password'] ?? '';

if (empty($identifier) || empty($password)) {
    echo json_encode(["success" => false, "message" => "Data tidak lengkap"]);
    exit;
}

// 1. Cek di tabel 'users' (Pelanggan)
$stmt_user = $conn->prepare("SELECT * FROM users WHERE email = ? OR no_hp = ? LIMIT 1");
$stmt_user->bind_param("ss", $identifier, $identifier);
$stmt_user->execute();
$result_user = $stmt_user->get_result();

if ($result_user && $result_user->num_rows > 0) {
    $user = $result_user->fetch_assoc();
    
    // Verifikasi password pelanggan
    if (password_verify($password, $user['password'])) {
        $foto_url = null;
        if (!empty($user['foto'])) {
            $foto_url = "http://192.168.1.7/test_application/uploads/" . $user['foto'];
        }
        
        echo json_encode([
            "success" => true,
            "message" => "Login pelanggan berhasil",
            "role" => "customer", // 💡 PENTING
            "data" => [
                "id"    => $user['id'],
                "nama"  => $user['nama'],
                "email" => $user['email'],
                "no_hp" => $user['no_hp'],
                "foto"  => $foto_url
            ]
        ]);
    } else {
        echo json_encode(["success" => false, "message" => "Password salah"]);
    }
    $stmt_user->close();
    $conn->close();
    exit; // Selesai
}
$stmt_user->close();

// 2. Jika tidak ditemukan, cek di tabel 'couriers' (Kurir)
$stmt_courier = $conn->prepare("SELECT * FROM couriers WHERE no_hp = ? LIMIT 1");
$stmt_courier->bind_param("s", $identifier);
$stmt_courier->execute();
$result_courier = $stmt_courier->get_result();

if ($result_courier && $result_courier->num_rows > 0) {
    $courier = $result_courier->fetch_assoc();
    
    // Verifikasi password kurir
    if (password_verify($password, $courier['password'])) {
        
        // 💡 TAMBAHAN: FORMAT URL FOTO KURIR
        $foto_url = null;
        if (!empty($courier['foto'])) {
            // GANTI IP SESUAI LAPTOP ANDA
            $foto_url = "http://192.168.1.7/test_application/uploads/" . $courier['foto'];
        }

        echo json_encode([
            "success" => true,
            "message" => "Login kurir berhasil",
            "role" => "courier", 
            "data" => [
                "id"   => $courier['id'],
                "nama" => $courier['nama'],
                "no_hp"=> $courier['no_hp'],
                "foto" => $foto_url // 💡 KIRIM FOTO KE FLUTTER
            ]
        ]);
    } else {
        echo json_encode(["success" => false, "message" => "Password salah"]);
    }
    $stmt_courier->close();
    $conn->close();
    exit; 
}
$stmt_courier->close();

echo json_encode(["success" => false, "message" => "Akun tidak ditemukan"]);
$conn->close();
?>