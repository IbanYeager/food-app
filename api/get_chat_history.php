<?php
// ===== api/get_chat_history.php (FILE BARU) =====
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include "config.php"; // $conn

$order_number = $_GET['order_number'] ?? '';

if (empty($order_number)) {
    http_response_code(400);
    echo json_encode([]);
    exit;
}

$messages = [];
$stmt = $conn->prepare("SELECT sender_role, message_text, created_at FROM chat_messages WHERE order_number = ? ORDER BY created_at ASC");
$stmt->bind_param("s", $order_number);

if ($stmt->execute()) {
    $result = $stmt->get_result();
    while ($row = $result->fetch_assoc()) {
        $messages[] = $row;
    }
}

$stmt->close();
$conn->close();

echo json_encode($messages);
?>