<?php
// ===== api/update_profile_unified.php =====
include "config.php"; 

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

$response = ["status" => "error", "message" => "Metode request tidak valid."];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = $_POST['id'] ?? null;
    $role = $_POST['role'] ?? 'customer'; // 'customer' atau 'courier'
    $nama = $_POST['nama'] ?? '';
    $email = $_POST['email'] ?? '';
    $no_hp = $_POST['no_hp'] ?? '';
    $password = $_POST['password'] ?? ''; // Password baru (opsional)

    if (!$id) {
        echo json_encode(["status" => "error", "message" => "ID User tidak ditemukan"]);
        exit;
    }

    // 1. Siapkan Bagian Foto
    $file_name = null;
    if (isset($_FILES['foto']) && $_FILES['foto']['error'] === UPLOAD_ERR_OK) {
        $target_dir = "../uploads/";
        if (!is_dir($target_dir)) mkdir($target_dir, 0777, true);

        $file_extension = strtolower(pathinfo($_FILES["foto"]["name"], PATHINFO_EXTENSION));
        $file_name = $role . "_" . $id . "_" . time() . "." . $file_extension;
        
        if (!move_uploaded_file($_FILES["foto"]["tmp_name"], $target_dir . $file_name)) {
            echo json_encode(["status" => "error", "message" => "Gagal upload gambar"]);
            exit;
        }
    }

    // 2. Siapkan Query berdasarkan Role & Input Password
    $table = ($role === 'courier') ? 'couriers' : 'users';
    
    // Mulai menyusun query dinamis
    $query = "UPDATE $table SET nama = ?, email = ?, no_hp = ?";
    $params = [$nama, $email, $no_hp];
    $types = "sss";

    // Jika ada foto baru, tambahkan ke query
    if ($file_name) {
        $query .= ", foto = ?";
        $params[] = $file_name;
        $types .= "s";
    }

    // Jika password diisi, hash dan tambahkan ke query
    if (!empty($password)) {
        $query .= ", password = ?";
        $params[] = password_hash($password, PASSWORD_BCRYPT);
        $types .= "s";
    }

    $query .= " WHERE id = ?";
    $params[] = $id;
    $types .= "i";

    // 3. Eksekusi
    $stmt = $conn->prepare($query);
    $stmt->bind_param($types, ...$params);

    if ($stmt->execute()) {
        // Ambil data terbaru untuk dikembalikan ke Flutter
        $stmt_get = $conn->prepare("SELECT id, nama, email, no_hp, foto FROM $table WHERE id = ?");
        $stmt_get->bind_param("i", $id);
        $stmt_get->execute();
        $result = $stmt_get->get_result();
        $newData = $result->fetch_assoc();

        // Format URL Foto lengkap
        if (!empty($newData['foto'])) {
            // GANTI IP INI SESUAI LAPTOP ANDA
            $newData['foto'] = "http://192.168.1.6/test_application/uploads/" . $newData['foto'];
        }

        echo json_encode([
            "status" => "success", 
            "message" => "Profil berhasil diperbarui",
            "data" => $newData
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "Gagal update DB: " . $stmt->error]);
    }
    $stmt->close();
}
$conn->close();
?>