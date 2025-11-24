<?php
// ===== api/get_active_couriers.php =====
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include "config.php"; // $conn

$couriers = [];

// Ambil semua kurir yang sedang aktif
$sql = "SELECT id, nama FROM couriers WHERE is_active = 1 ORDER BY nama ASC";
$result = $conn->query($sql);

if ($result) {
    while ($row = $result->fetch_assoc()) {
        $couriers[] = $row;
    }
}

echo json_encode($couriers);

$conn->close();
?>