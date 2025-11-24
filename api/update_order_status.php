<?php
// ===== api/update_order_status.php =====

// 1. Header CORS (Wajib untuk akses beda jaringan/device)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// Tangani preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

header("Content-Type: application/json; charset=UTF-8");
include "config.php"; // Koneksi Database
require __DIR__ . '/../vendor/autoload.php'; // Library Pusher

// 2. Konfigurasi Pusher
$options = array(
    'cluster' => 'ap1',
    'useTLS' => true
);
$pusher = new Pusher\Pusher(
    '2c68d0ff3232cd32c50f', // Kunci Aplikasi (Key)
    '1fd7c8391e08c54d0d6b', // Rahasia Aplikasi (Secret)
    '2075465',              // ID Aplikasi (App ID)
    $options
);

// 3. Ambil Data JSON
$data = json_decode(file_get_contents("php://input"));

$order_number = $data->order_number ?? '';
$new_status   = $data->status ?? '';
$courier_id   = $data->courier_id ?? null;

// 4. Validasi Input Dasar
if (empty($order_number) || empty($new_status)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Order number dan status wajib diisi']);
    exit;
}

// 5. Validasi Status yang Diizinkan
// 'Selesai' WAJIB ada di sini agar Kurir bisa menyelesaikan pesanan
$allowed_statuses = ['Dikonfirmasi', 'Dibatalkan', 'Diantar', 'Selesai'];

if (!in_array($new_status, $allowed_statuses)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Status tidak valid']);
    exit;
}

try {
    // 6. Siapkan Query Update Database
    // Jika status 'Diantar', kita juga harus menyimpan ID Kurir
    if ($new_status == 'Diantar' && $courier_id) {
        $stmt = $conn->prepare("UPDATE orders SET status = ?, courier_id = ? WHERE order_number = ?");
        $stmt->bind_param("sis", $new_status, $courier_id, $order_number);
    } else {
        // Untuk status lain (Dikonfirmasi, Dibatalkan, Selesai), hanya update status
        $stmt = $conn->prepare("UPDATE orders SET status = ? WHERE order_number = ?");
        $stmt->bind_param("ss", $new_status, $order_number);
    }

    // 7. Eksekusi Query
    if ($stmt->execute()) {
        // Cek apakah ada baris yang berubah ATAU statusnya 'Selesai' (idempotent)
        if ($stmt->affected_rows > 0 || $new_status == 'Selesai') {

            // --- LOGIKA NOTIFIKASI PUSHER ---

            // A. Notifikasi ke USER (Customer)
            // Dikirim ke channel tracking pesanan tersebut
            $channel_user = 'order-tracking-' . $order_number;
            $event_user = 'status-update';
            
            $pesanUser = '';
            if ($new_status == 'Diantar') $pesanUser = 'Pesanan Anda sedang diantar oleh kurir!';
            if ($new_status == 'Selesai') $pesanUser = 'Pesanan telah selesai. Terima kasih!';
            if ($new_status == 'Dibatalkan') $pesanUser = 'Mohon maaf, pesanan Anda dibatalkan.';
            if ($new_status == 'Dikonfirmasi') $pesanUser = 'Pesanan Anda telah dikonfirmasi dapur.';

            if (!empty($pesanUser)) {
                try {
                    $pusher->trigger($channel_user, $event_user, [
                        'status' => $new_status,
                        'message' => $pesanUser
                    ]);
                } catch (Exception $e) {
                    error_log("Pusher User Error: " . $e->getMessage());
                }
            }

            // B. Notifikasi ke KURIR (Hanya jika status 'Diantar')
            // Ini agar Dashboard Kurir otomatis refresh saat ada tugas baru
            if ($new_status == 'Diantar' && !empty($courier_id)) {
                $channel_courier = 'courier-' . $courier_id; // Channel pribadi kurir
                $event_courier = 'new-job';

                $dataKurir = [
                    'message' => 'Tugas pengantaran baru masuk!',
                    'order_number' => $order_number
                ];

                try {
                    $pusher->trigger($channel_courier, $event_courier, $dataKurir);
                } catch (Exception $e) {
                    error_log("Pusher Courier Error: " . $e->getMessage());
                }
            }

            if ($new_status == 'Selesai') {
                try {
                    // Kita kirim ke 'order-channel' yang sudah didengarkan oleh dashboard.html
                    $pusher->trigger('order-channel', 'order-finished', [
                        'order_number' => $order_number,
                        'status' => 'Selesai',
                        'message' => "Pesanan #$order_number telah selesai diantar!",
                        'waktu_selesai' => date('H:i')
                    ]);
                } catch (Exception $e) {
                    error_log("Pusher Admin Error: " . $e->getMessage());
                }
            }

            // --- SELESAI ---

            echo json_encode(['success' => true, 'message' => 'Status berhasil diperbarui']);
        } else {
            // Tidak ada perubahan (mungkin status sudah sama sebelumnya)
            echo json_encode(['success' => true, 'message' => 'Status sudah sesuai (tidak ada perubahan)']);
        }
    } else {
        throw new Exception("Gagal eksekusi database: " . $stmt->error);
    }
    
    $stmt->close();

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>