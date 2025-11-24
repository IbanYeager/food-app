<?php
// ===== api/update_delivery_status.php =====
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

include "config.php"; // $conn
require __DIR__ . '/../vendor/autoload.php'; // Sesuaikan path ke Pusher

// --- KUNCI PUSHER ANDA ---
$options = array(
    'cluster' => 'ap1', // ganti dengan cluster Anda
    'useTLS' => true
);
$pusher = new Pusher\Pusher(
    '2c68d0ff3232cd32c50f', // ganti KUNCI
    '1fd7c8391e08c54d0d6b', // ganti SECRET
    '2075465', // ganti APP_ID
    $options
);
// -------------------------------------

$data = json_decode(file_get_contents("php://input"));
$order_number = $data->order_number ?? '';
$courier_id = $data->courier_id ?? 0;
$new_status = $data->status ?? ''; // Harus 'Diantar'

if (empty($order_number) || $new_status !== 'Diantar' || empty($courier_id)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Data tidak valid (order_number, courier_id, dan status=Diantar wajib diisi)']);
    exit;
}

// 1. Update database
$stmt = $conn->prepare("UPDATE orders SET status = ?, courier_id = ? WHERE order_number = ?");
$stmt->bind_param("sis", $new_status, $courier_id, $order_number);

if ($stmt->execute()) {
    // 2. Kirim trigger notifikasi ke User (Pusher)
    $channel_name = 'order-tracking-' . $order_number;
    $event_name = 'status-update'; // Event untuk notifikasi
    $dataPesan = [
        'status' => $new_status,
        'message' => 'Pesanan Anda sedang diantar oleh kurir!'
    ];

    try {
        $pusher->trigger($channel_name, $event_name, $dataPesan);
    } catch (Exception $e) {
        error_log("PUSHER_ERROR: " . $e->getMessage());
    }

    echo json_encode(['success' => true, 'message' => 'Status berhasil diupdate']);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Gagal update database: ' . $stmt->error]);
}
$stmt->close();
$conn->close();
?>