<?php
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        "success" => false,
        "message" => "Metode tidak valid"
    ]);
    exit;
}

include "config.php";

$nama = $_POST['nama'] ?? '';
$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';
$no_hp = $_POST['no_hp'] ?? '';

if ($nama && $email && $password && $no_hp) {
    $passwordHash = password_hash($password, PASSWORD_BCRYPT);
    $query = "INSERT INTO users (nama, email, password, no_hp) VALUES ('$nama', '$email', '$passwordHash', '$no_hp')";
    if (mysqli_query($conn, $query)) {
        echo json_encode([
            "success" => true,
            "message" => "Registrasi berhasil"
        ]);
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Gagal registrasi: " . mysqli_error($conn)
        ]);
    }
} else {
    echo json_encode([
        "success" => false,
        "message" => "Data tidak lengkap"
    ]);
}
