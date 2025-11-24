<?php
// ===== api/get_courier_history.php =====
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include "config.php";

$courier_id = $_GET['courier_id'] ?? 0;

if ($courier_id == 0) {
    echo json_encode([]);
    exit;
}

// 💡 PERBAIKAN QUERY: Pastikan 'Selesai' masuk dalam daftar pencarian
$sql = "SELECT 
            o.order_number, 
            o.total, 
            o.date AS waktu, 
            o.status,
            u.nama AS nama_user
        FROM orders o
        JOIN users u ON o.user_id = u.id
        WHERE o.courier_id = ? 
        AND o.status IN ('Selesai', 'Dibatalkan') 
        ORDER BY o.date DESC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $courier_id);
$stmt->execute();
$result = $stmt->get_result();

$orders = [];
while ($row = $result->fetch_assoc()) {
    $orders[] = $row;
}

echo json_encode($orders);

$stmt->close();
$conn->close();
?>