<?php
// ===== api/send_message.php (FILE BARU) =====
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
    'cluster' => 'ap1', // ganti cluster
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
$sender_role = $data->sender_role ?? ''; // 'customer' atau 'courier'
$message_text = $data->message_text ?? '';

if (empty($order_number) || empty($sender_role) || empty($message_text)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Data tidak lengkap']);
    exit;
}

// 1. Simpan pesan ke database
$stmt = $conn->prepare("INSERT INTO chat_messages (order_number, sender_role, message_text) VALUES (?, ?, ?)");
$stmt->bind_param("sss", $order_number, $sender_role, $message_text);

if ($stmt->execute()) {
    // 2. Kirim trigger ke Pusher (ke channel yang sudah ada)
    $channel_name = 'order-tracking-' . $order_number;
    $event_name = 'new-message'; // 💡 Event baru
    
    $messageData = [
        'sender_role' => $sender_role,
        'message_text' => $message_text,
        'created_at' => date('Y-m-d H:i:s')
    ];

    try {
        $pusher->trigger($channel_name, $event_name, $messageData);
    } catch (Exception $e) {
        error_log("PUSHER_ERROR: " . $e->getMessage());
    }

    echo json_encode(['success' => true, 'message' => 'Pesan terkirim']);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Gagal menyimpan pesan']);
}

$stmt->close();
$conn->close();
?>