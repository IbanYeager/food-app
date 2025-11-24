<?php
// ===== api/get_completed_orders.php =====
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include "config.php";

// Ambil 20 pesanan terakhir yang sudah selesai
$sql = "SELECT 
            o.order_number, o.total, o.date AS waktu, o.status,
            u.nama AS nama_user, c.nama AS nama_kurir
        FROM orders o
        JOIN users u ON o.user_id = u.id
        LEFT JOIN couriers c ON o.courier_id = c.id
        WHERE o.status = 'Selesai'
        ORDER BY o.date DESC LIMIT 20";

$result = $conn->query($sql);
$orders = [];

while ($row = $result->fetch_assoc()) {
    $orders[] = $row;
}

echo json_encode($orders);
$conn->close();
?>