<?php
// ===== api/get_confirmed_orders.php (FILE BARU) =====
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include "config.php"; // Pastikan $conn ada di sini

$confirmed_orders = [];

try {
    // Ambil semua pesanan yang statusnya 'Dikonfirmasi'
    // Kita juga JOIN dengan tabel 'users' untuk mendapat nama pelanggan
    // Dan kita ambil semua data lokasi (origin & destination)
    
    $sql_orders = "SELECT 
                        o.order_number, 
                        o.total, 
                        o.date AS waktu, 
                        o.origin_lat, 
                        o.origin_lng, 
                        o.destination_lat, 
                        o.destination_lng,
                        u.nama AS nama_user,
                        u.no_hp AS no_hp_user
                   FROM orders o
                   JOIN users u ON o.user_id = u.id
                   WHERE o.status = 'Dikonfirmasi' 
                   ORDER BY o.date ASC"; // Tampilkan yang paling lama dikonfirmasi
                       
    $result_orders = $conn->query($sql_orders);

    if (!$result_orders) {
        throw new Exception("Gagal mengambil pesanan: " . $conn->error);
    }

    while ($order = $result_orders->fetch_assoc()) {
        $confirmed_orders[] = $order;
    }

    $result_orders->close();
    $conn->close();

    echo json_encode($confirmed_orders);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>