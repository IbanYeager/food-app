<?php
// ===== HEADER PENTING UNTUK FIX "GA ADA KONEKSI" (CORS) =====
header("Access-Control-Allow-Origin: *"); 
header("Access-Control-Allow-Methods: POST, OPTIONS"); 
header("Access-Control-Allow-Headers: Content-Type"); 

// Tangani request pre-flight (OPTIONS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}
// =============================================================

header("Content-Type: application/json; charset=UTF-8");
include "config.php"; // Pastikan $conn ada di sini

// Ambil data JSON yang dikirim dari JavaScript
$data = json_decode(file_get_contents("php://input"));
$order_number = $data->order_number ?? '';

if (empty($order_number)) {
    http_response_code(400); // Bad Request
    echo json_encode(['success' => false, 'message' => 'Order number tidak boleh kosong']);
    exit;
}

// Mulai Transaksi
mysqli_autocommit($conn, FALSE);
$error_flag = false;
$error_message = '';

try {
    // 1. Ambil 'id' (Primary Key) dari tabel 'orders' berdasarkan 'order_number'
    $order_id = 0;
    $stmt_get_id = $conn->prepare("SELECT id FROM orders WHERE order_number = ?");
    if (!$stmt_get_id) throw new Exception("Gagal prepare 1: " . $conn->error);
    
    $stmt_get_id->bind_param("s", $order_number);
    $stmt_get_id->execute();
    $result_id = $stmt_get_id->get_result();
    
    if ($row = $result_id->fetch_assoc()) {
        $order_id = $row['id'];
    }
    $stmt_get_id->close();

    if ($order_id > 0) {
        // 2. Hapus dari 'order_details' terlebih dahulu (child table)
        $stmt_delete_details = $conn->prepare("DELETE FROM order_details WHERE order_id = ?");
        if (!$stmt_delete_details) throw new Exception("Gagal prepare 2: " . $conn->error);
        
        $stmt_delete_details->bind_param("i", $order_id);
        if (!$stmt_delete_details->execute()) {
            $error_flag = true;
            $error_message = $stmt_delete_details->error;
        }
        $stmt_delete_details->close();
    } else {
        // Order number tidak ditemukan, tapi kita tetap coba hapus dari tabel orders
        // untuk memastikan (walaupun seharusnya tidak ada)
    }

    if (!$error_flag) {
        // 3. Hapus dari 'orders' (parent table)
        $stmt_delete_order = $conn->prepare("DELETE FROM orders WHERE order_number = ?");
        if (!$stmt_delete_order) throw new Exception("Gagal prepare 3: " . $conn->error);
        
        $stmt_delete_order->bind_param("s", $order_number);
        if (!$stmt_delete_order->execute()) {
            $error_flag = true;
            $error_message = $stmt_delete_order->error;
        }
        $stmt_delete_order->close();
    }

} catch (Exception $e) {
    $error_flag = true;
    $error_message = $e->getMessage();
}

// 4. Selesaikan Transaksi
if ($error_flag) {
    mysqli_rollback($conn);
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Gagal menghapus pesanan: ' . $error_message]);
} else {
    mysqli_commit($conn);
    echo json_encode(['success' => true, 'message' => 'Riwayat pesanan berhasil dihapus']);
}

mysqli_autocommit($conn, TRUE);
$conn->close();
?>