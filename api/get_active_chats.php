<?php
// ===== api/get_active_chats.php (FILE BARU) =====
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

include "config.php"; // $conn

$role = $_GET['role'] ?? '';
$id = $_GET['id'] ?? 0;

if (empty($role) || empty($id)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Role and ID are required']);
    exit;
}

$active_chats = [];

try {
    if ($role == 'customer') {
        // -------------------------------------
        // JIKA CUSTOMER: Cari order dia, ambil nama kurir
        // -------------------------------------
        $sql = "SELECT 
                    o.order_number, 
                    o.origin_lat, o.origin_lng, 
                    o.destination_lat, o.destination_lng,
                    c.nama AS other_party_name
                FROM orders o
                JOIN couriers c ON o.courier_id = c.id
                WHERE o.user_id = ? AND o.status = 'Diantar'
                ORDER BY o.date DESC";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $id);

    } else if ($role == 'courier') {
        // -------------------------------------
        // JIKA KURIR: Cari order dia, ambil nama customer
        // -------------------------------------
        $sql = "SELECT 
                    o.order_number, 
                    o.origin_lat, o.origin_lng, 
                    o.destination_lat, o.destination_lng,
                    u.nama AS other_party_name
                FROM orders o
                JOIN users u ON o.user_id = u.id
                WHERE o.courier_id = ? AND o.status = 'Diantar'
                ORDER BY o.date DESC";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $id);

    } else {
        throw new Exception("Role tidak valid");
    }

    if (!$stmt) {
        throw new Exception("Gagal prepare statement: " . $conn->error);
    }

    $stmt->execute();
    $result = $stmt->get_result();
    while ($row = $result->fetch_assoc()) {
        $active_chats[] = $row;
    }
    
    $stmt->close();
    $conn->close();

    echo json_encode($active_chats);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>