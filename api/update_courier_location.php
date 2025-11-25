<?php
// ===== api/update_courier_location.php (FIXED) =====
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

// Handle Preflight Request (CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

include "config.php"; 
require __DIR__ . '/../vendor/autoload.php';

// --- 1. INISIALISASI PUSHER ---
$options = array(
    'cluster' => 'ap1',
    'useTLS' => true
);
$pusher = new Pusher\Pusher(
    '2c68d0ff3232cd32c50f', // Key
    '1fd7c8391e08c54d0d6b', // Secret
    '2075465', // App ID
    $options
);

// --- 2. AMBIL DATA INPUT ---
$data = json_decode(file_get_contents("php://input"));

$courier_id = $data->courier_id ?? 0;
$lat = $data->lat ?? 0;
$lng = $data->lng ?? 0;
$order_number = $data->order_number ?? '';

if (empty($courier_id) || $lat == 0) {
    echo json_encode(['success' => false, 'message' => 'Data lokasi tidak valid']);
    exit;
}

// --- 3. UPDATE DATABASE ---
$stmt = $conn->prepare("UPDATE couriers SET current_lat = ?, current_lng = ?, last_updated = NOW() WHERE id = ?");
$stmt->bind_param("ddi", $lat, $lng, $courier_id);
$stmt->execute();
$stmt->close();

// --- 4. AMBIL DATA FOTO DARI DATABASE ---
$nama_kurir = "Kurir";
$foto_url = ""; // Default kosong

$q = $conn->query("SELECT nama, foto FROM couriers WHERE id = $courier_id");
if ($q && $row = $q->fetch_assoc()) {
    $nama_kurir = $row['nama'];
    if (!empty($row['foto'])) {
        // 💡 Membangun URL lengkap foto
        // Pastikan IP ini (192.168.1.6) sesuai dengan IP laptop Anda saat ini
        $foto_url = "http://192.168.1.7/test_application/uploads/" . $row['foto'];
    }
}

// --- 5. KIRIM KE ADMIN DASHBOARD (Channel Global) ---
// Data ini yang ditangkap dashboard.html untuk update marker peta
try {
    $pusher->trigger('admin-channel', 'courier-moved', [
        'id' => $courier_id,
        'nama' => $nama_kurir,
        'foto' => $foto_url, // 💡 Kirim URL foto ke admin map
        'lat' => $lat,
        'lng' => $lng,
        'order_number' => $order_number
    ]);
} catch (Exception $e) {
    // Error handling silent agar kurir tetap jalan meski pusher gagal
}

// --- 6. KIRIM KE USER / CUSTOMER (Channel Order) ---
if (!empty($order_number)) {
    try {
        $pusher->trigger('order-tracking-' . $order_number, 'location-update', [
            'lat' => $lat,
            'lng' => $lng
        ]);
    } catch (Exception $e) {
        // Error handling silent
    }
}

echo json_encode(['success' => true]);
$conn->close();
?>