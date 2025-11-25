<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include "config.php";

// Ambil kurir yang aktif 1 jam terakhir
$sql = "SELECT id, nama, foto, current_lat, current_lng, no_hp 
        FROM couriers 
        WHERE current_lat IS NOT NULL 
        AND last_updated >= DATE_SUB(NOW(), INTERVAL 1 HOUR)";

$result = $conn->query($sql);
$couriers = [];

while($row = $result->fetch_assoc()) {
    // 💡 WAJIB: Tambahkan URL lengkap untuk foto
    if (!empty($row['foto'])) {
        // GANTI IP INI SESUAI LAPTOP ANDA
        $row['foto'] = "http://192.168.1.7/test_application/uploads/" . $row['foto'];
    } else {
        $row['foto'] = ""; 
    }
    
    // Pastikan koordinat berupa angka (float)
    $row['current_lat'] = (float)$row['current_lat'];
    $row['current_lng'] = (float)$row['current_lng'];
    
    $couriers[] = $row;
}

echo json_encode($couriers);
?>