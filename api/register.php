<?php
// ===== api/register.php (MODIFIKASI) =====
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(["success" => false, "message" => "Metode tidak valid"]);
    exit;
}

include "config.php"; // $conn

// 1. Ambil semua data
$nama = $_POST['nama'] ?? '';
$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';
$no_hp = $_POST['no_hp'] ?? '';
$role = $_POST['role'] ?? ''; // 💡 BARU: Ambil role

// 2. Validasi data
if (empty($nama) || empty($password) || empty($no_hp) || empty($role)) {
    echo json_encode(["success" => false, "message" => "Nama, Password, No. HP, dan Role tidak boleh kosong"]);
    exit;
}

// 3. Hash password
$passwordHash = password_hash($password, PASSWORD_BCRYPT);


// 4. Logika berdasarkan ROLE
if ($role == 'customer') {
    // --- PENDAFTARAN CUSTOMER ---
    
    // Validasi email (wajib untuk customer)
    if (empty($email)) {
        echo json_encode(["success" => false, "message" => "Email wajib diisi untuk pelanggan"]);
        exit;
    }

    // Cek duplikat di tabel 'users'
    $stmt_check = $conn->prepare("SELECT id FROM users WHERE email = ? OR no_hp = ?");
    $stmt_check->bind_param("ss", $email, $no_hp);
    $stmt_check->execute();
    $result_check = $stmt_check->get_result();

    if ($result_check->num_rows > 0) {
        echo json_encode(["success" => false, "message" => "Email atau No HP sudah terdaftar sebagai pelanggan"]);
    } else {
        // Masukkan ke tabel 'users'
        $stmt_insert = $conn->prepare("INSERT INTO users (nama, email, password, no_hp) VALUES (?, ?, ?, ?)");
        $stmt_insert->bind_param("ssss", $nama, $email, $passwordHash, $no_hp);
        
        if ($stmt_insert->execute()) {
            echo json_encode(["success" => true, "message" => "Registrasi pelanggan berhasil"]);
        } else {
            echo json_encode(["success" => false, "message" => "Gagal registrasi: " . $stmt_insert->error]);
        }
        $stmt_insert->close();
    }
    $stmt_check->close();

} else if ($role == 'courier') {
    // --- PENDAFTARAN KURIR ---
    
    // Cek duplikat di tabel 'couriers' (hanya No HP)
    $stmt_check = $conn->prepare("SELECT id FROM couriers WHERE no_hp = ?");
    $stmt_check->bind_param("s", $no_hp);
    $stmt_check->execute();
    $result_check = $stmt_check->get_result();

    if ($result_check->num_rows > 0) {
        echo json_encode(["success" => false, "message" => "No HP ini sudah terdaftar sebagai kurir"]);
    } else {
        // Masukkan ke tabel 'couriers' (Email diabaikan)
        $stmt_insert = $conn->prepare("INSERT INTO couriers (nama, no_hp, password) VALUES (?, ?, ?)");
        $stmt_insert->bind_param("sss", $nama, $no_hp, $passwordHash);
        
        if ($stmt_insert->execute()) {
            echo json_encode(["success" => true, "message" => "Registrasi kurir berhasil"]);
        } else {
            echo json_encode(["success" => false, "message" => "Gagal registrasi: " . $stmt_insert->error]);
        }
        $stmt_insert->close();
    }
    $stmt_check->close();

} else {
    // Role tidak valid
    echo json_encode(["success" => false, "message" => "Role tidak valid"]);
}

$conn->close();
?>