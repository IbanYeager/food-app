<?php
// ===== api/buat_pesanan.php (VERSI ANTI-CRASH & DEBUGGING) =====

// Matikan output error HTML standar agar tidak merusak JSON
ini_set('display_errors', 0);
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

// Gunakan Global Try-Catch untuk menangkap Fatal Error
try {
    include "config.php"; 

    // 1. Cek Koneksi DB
    if (!isset($conn) || $conn->connect_error) {
        throw new Exception("Koneksi Database Gagal: " . ($conn->connect_error ?? 'Unknown error'));
    }

    // 2. Decode Data JSON
    $inputJSON = file_get_contents("php://input");
    $data = json_decode($inputJSON);

    if (is_null($data)) {
        throw new Exception("Gagal membaca data JSON dari Flutter.");
    }

    $user_id = $data->user_id ?? 0;
    $total = $data->total ?? 0;
    $items = $data->items ?? [];
    $dest_lat = $data->user_lat ?? 0;
    $dest_lng = $data->user_lng ?? 0;

    // Validasi Input
    if (empty($user_id) || empty($total) || empty($items)) {
        throw new Exception("Data pesanan tidak lengkap (User ID / Total / Items kosong).");
    }

    // 3. Logika Pusher (Diisolasi agar jika gagal, order tetap masuk)
    $pusher = null;
    try {
        // Cek apakah file autoload ada sebelum di-require
        $autoloadPath = __DIR__ . '/../vendor/autoload.php';
        if (file_exists($autoloadPath)) {
            require_once $autoloadPath;
            
            $options = array(
                'cluster' => 'ap1',
                'useTLS' => true
            );
            // Pastikan class ada
            if (class_exists('Pusher\Pusher')) {
                $pusher = new Pusher\Pusher(
                    '2c68d0ff3232cd32c50f',
                    '1fd7c8391e08c54d0d6b',
                    '2075465',
                    $options
                );
            }
        }
    } catch (Throwable $t) {
        // Abaikan error Pusher, lanjut simpan ke DB
        // error_log("Pusher Error: " . $t->getMessage());
    }

    // 4. Siapkan Data Lain
    $order_number = 'ORD-' . $user_id . '-' . time();
    
    $first_item_id = 0;
    if (count($items) > 0) {
        $first_item_id = intval($items[0]->id);
    }

    $origin_lat = 0.0;
    $origin_lng = 0.0;

    if ($first_item_id > 0) {
        if ($stmt_menu) {
            $stmt_menu->bind_param("i", $first_item_id);
            if ($stmt_menu->execute()) {
                $res_menu = $stmt_menu->get_result();
                if ($row_menu = $res_menu->fetch_assoc()) {
                    $origin_lat = floatval($row_menu['latitude']);
                    $origin_lng = floatval($row_menu['longitude']);
                }
            }
            $stmt_menu->close();
        }
    }

    // 5. Mulai Transaksi Database
    $conn->begin_transaction();

    try {
        // Insert Orders
        $stmt_order = $conn->prepare("INSERT INTO orders (user_id, order_number, total, status, date, origin_lat, origin_lng, destination_lat, destination_lng) VALUES (?, ?, ?, 'Pending', NOW(), ?, ?, ?, ?)");
        
        if (!$stmt_order) {
            throw new Exception("SQL Error (Orders): " . $conn->error);
        }

        // Pastikan tipe data float untuk koordinat
        $d_origin_lat = (double)$origin_lat;
        $d_origin_lng = (double)$origin_lng;
        $d_dest_lat = (double)$dest_lat;
        $d_dest_lng = (double)$dest_lng;
        $d_total = (double)$total;

        $stmt_order->bind_param("isddddd", $user_id, $order_number, $d_total, $d_origin_lat, $d_origin_lng, $d_dest_lat, $d_dest_lng);

        if (!$stmt_order->execute()) {
            throw new Exception("Gagal Execute Order: " . $stmt_order->error);
        }
        
        $order_id = $conn->insert_id;
        $stmt_order->close();

        // Insert Details
        $stmt_detail = $conn->prepare("INSERT INTO order_details (order_id, menu_id, nama_menu, harga, quantity) VALUES (?, ?, ?, ?, ?)");
        
        if (!$stmt_detail) {
            throw new Exception("SQL Error (Details): " . $conn->error);
        }

        foreach ($items as $item) {
            $menu_id = intval($item->id); 
            $nama_menu = $item->nama ?? 'Unknown';
            $harga = (double)($item->harga ?? 0);
            $qty = intval($item->quantity ?? 1);

            $stmt_detail->bind_param("iisdi", $order_id, $menu_id, $nama_menu, $harga, $qty);
            
            if (!$stmt_detail->execute()) {
                throw new Exception("Gagal Execute Detail Item ($nama_menu): " . $stmt_detail->error);
            }
        }
        $stmt_detail->close();

        // Jika semua lancar, Commit
        $conn->commit();

        // Kirim response sukses dulu ke HP
        $response = [
            'success' => true, 
            'message' => 'Pesanan berhasil dibuat', 
            'order_number' => $order_number
        ];

        // Trigger Pusher (Jika berhasil di-load tadi)
        if ($pusher) {
            // Ambil nama user
            $nama_user = "User " . $user_id; 
            $q_u = $conn->query("SELECT nama FROM users WHERE id = $user_id");
            if ($q_u && $row_u = $q_u->fetch_assoc()) {
                $nama_user = $row_u['nama'];
            }

            $dataPesan = [
                'order_number' => $order_number,
                'total' => $total,
                'user_id' => $user_id,
                'nama_user' => $nama_user,
                'waktu' => date('Y-m-d H:i:s'),
                'items' => $items
            ];
            $pusher->trigger('order-channel', 'new-order', $dataPesan);
        }

        echo json_encode($response);

    } catch (Exception $e) {
        $conn->rollback(); // Batalkan jika ada error saat insert
        throw $e; // Lempar ke catch global
    }

} catch (Throwable $e) {
    // TANGKAP FATAL ERROR / EXCEPTION APAPUN
    // Kirim sebagai JSON agar terbaca di HP, bukan Error 500
    http_response_code(200); // Tetap return 200 agar Flutter bisa baca JSON-nya
    echo json_encode([
        "success" => false,
        "message" => "Server Error: " . $e->getMessage() . " (Line: " . $e->getLine() . ")"
    ]);
}

if (isset($conn)) {
    $conn->close();
}
?>