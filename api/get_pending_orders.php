<?php
// ===== api/get_pending_orders.php (DENGAN ITEM) =====
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include "config.php";

$pending_orders = [];

try {
    // 1. Ambil Pesanan Utama (tambah o.id untuk join ke details)
    $sql_orders = "SELECT o.id, o.order_number, o.total, o.user_id, o.date AS waktu, u.nama AS nama_user
                   FROM orders o
                   JOIN users u ON o.user_id = u.id
                   WHERE o.status = 'Pending' 
                   ORDER BY o.date ASC";
                   
    $result_orders = $conn->query($sql_orders);

    if ($result_orders) {
        while ($order = $result_orders->fetch_assoc()) {
            $order_id = $order['id'];
            
            // 2. 💡 AMBIL ITEM (DETAIL) UNTUK SETIAP PESANAN
            $sql_items = "SELECT nama_menu, quantity FROM order_details WHERE order_id = $order_id";
            $result_items = $conn->query($sql_items);
            
            $items = [];
            if ($result_items) {
                while ($item = $result_items->fetch_assoc()) {
                    $items[] = $item; // Masukkan menu & qty ke array
                }
            }
            
            // Masukkan array items ke dalam object order
            $order['items'] = $items;
            
            $pending_orders[] = $order;
        }
    }

    echo json_encode($pending_orders);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>