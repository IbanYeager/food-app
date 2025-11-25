<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include "config.php";

$completed_orders = [];

try {
    // 1. Ambil Data Pesanan Utama
    // PENTING: Kita harus mengambil 'o.id' untuk dipakai mencari detail item
    $sql = "SELECT 
                o.id, 
                o.order_number, 
                o.total, 
                o.date AS waktu, 
                o.date AS waktu_selesai, 
                o.status, 
                u.nama AS nama_user, 
                c.nama AS nama_kurir
            FROM orders o
            JOIN users u ON o.user_id = u.id
            LEFT JOIN couriers c ON o.courier_id = c.id
            WHERE o.status = 'Selesai'
            ORDER BY o.date DESC LIMIT 20";

    $result = $conn->query($sql);

    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $order_id = $row['id'];

            // 2. QUERY KE-2: Ambil Detail Menu berdasarkan ID Pesanan
            $sql_items = "SELECT nama_menu, quantity, harga FROM order_details WHERE order_id = $order_id";
            $res_items = $conn->query($sql_items);
            
            $items = [];
            if ($res_items) {
                while ($item = $res_items->fetch_assoc()) {
                    $items[] = $item; // Masukkan menu ke array sementara
                }
            }

            // 3. Gabungkan array items ke dalam data pesanan utama
            // Inilah yang dibaca oleh Javascript (data.items)
            $row['items'] = $items;
            
            $completed_orders[] = $row;
        }
    }

    echo json_encode($completed_orders);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}

$conn->close();
?>