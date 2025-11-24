<?php
// ===== api/orders.php (MODIFIKASI) =====
header("Content-Type: application/json; charset=UTF-8");
include "config.php"; // $conn

$user_id = $_GET['user_id'] ?? 0;

if ($user_id <= 0) {
    echo json_encode([]); // Kembalikan array kosong jika user_id tidak valid
    exit;
}

// 💡 MODIFIKASI: Pilih kolom lokasi yang baru
$stmt = $conn->prepare("SELECT 
    order_number, status, date, total, 
    origin_lat, origin_lng, destination_lat, destination_lng 
    FROM orders 
    WHERE user_id = ? ORDER BY date DESC");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$orders = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        // 💡 MODIFIKASI: Tambahkan data baru ke response
        $orders[] = [
            'orderNumber' => $row['order_number'],
            'status' => $row['status'],
            'date' => $row['date'],
            'total' => $row['total'],
            'origin_lat' => $row['origin_lat'],
            'origin_lng' => $row['origin_lng'],
            'destination_lat' => $row['destination_lat'],
            'destination_lng' => $row['destination_lng']
        ];
    }
}

echo json_encode($orders);

$stmt->close();
$conn->close();
?>