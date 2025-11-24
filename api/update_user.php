<?php
include "config.php"; // Pastikan file config.php berisi koneksi ke database ($conn)

header('Content-Type: application/json');

// 💡 1. Tentukan base URL untuk folder upload secara statis dan benar.
// Ganti 192.168.1.6 sesuai dengan IP address server Anda.
$upload_base_url = "http://192.168.1.6/test_application/uploads/";

$response = ["status" => "error", "message" => "Metode request tidak valid."];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = $_POST['id'] ?? null;
    $nama = $_POST['nama'] ?? null;
    $no_hp = $_POST['no_hp'] ?? null;
    $email = $_POST['email'] ?? null;

    if ($id === null || $nama === null || $email === null || $no_hp === null) {
        $response['message'] = "Data tidak lengkap.";
        echo json_encode($response);
        exit;
    }

    $file_name = null; // Variabel untuk menyimpan NAMA FILE saja.

    if (isset($_FILES['foto']) && $_FILES['foto']['error'] === UPLOAD_ERR_OK) {
        $target_dir = "../uploads/"; // 💡 2. Arahkan ke folder 'uploads' di luar folder 'api'

        if (!is_dir($target_dir)) {
            mkdir($target_dir, 0777, true);
        }

        $file_extension = strtolower(pathinfo($_FILES["foto"]["name"], PATHINFO_EXTENSION));
        // 💡 3. Simpan hanya nama file ke variabel
        $file_name = "user_" . $id . "_" . time() . "." . $file_extension;
        $target_file = $target_dir . $file_name;

        if (!move_uploaded_file($_FILES["foto"]["tmp_name"], $target_file)) {
            $response['message'] = "Gagal memindahkan file yang diupload. Periksa izin folder 'uploads'.";
            echo json_encode($response);
            exit;
        }
    }

    if ($file_name) {
        // Jika ada file baru, update semua kolom termasuk foto
        $query = "UPDATE users SET nama = ?, email = ?, no_hp = ?, foto = ? WHERE id = ?";
        $stmt = mysqli_prepare($conn, $query);
        // 💡 4. Bind $file_name (bukan path lengkap) ke query
        mysqli_stmt_bind_param($stmt, "ssssi", $nama, $email, $no_hp, $file_name, $id);
    } else {
        // Jika tidak ada file baru, update data teks saja
        $query = "UPDATE users SET nama = ?, email = ?, no_hp = ? WHERE id = ?";
        $stmt = mysqli_prepare($conn, $query);
        mysqli_stmt_bind_param($stmt, "sssi", $nama, $email, $no_hp, $id);
    }

    if (mysqli_stmt_execute($stmt)) {
        mysqli_stmt_close($stmt);

        // Ambil kembali data terbaru dari database untuk dikirim balik ke Flutter
        $query_select = "SELECT id, nama, email, no_hp, foto FROM users WHERE id = ?";
        $stmt_select = mysqli_prepare($conn, $query_select);
        mysqli_stmt_bind_param($stmt_select, "i", $id);
        mysqli_stmt_execute($stmt_select);
        $result = mysqli_stmt_get_result($stmt_select);
        $user_data = mysqli_fetch_assoc($result);

        // 💡 5. Ubah nama file menjadi URL lengkap sebelum dikirim ke Flutter
        if ($user_data && !empty($user_data['foto'])) {
            $user_data['foto'] = $upload_base_url . $user_data['foto'];
        }
        
        $response['status'] = "success";
        $response['message'] = "Profil berhasil diperbarui.";
        $response['data'] = $user_data;
        mysqli_stmt_close($stmt_select);

    } else {
        $response['message'] = "Gagal memperbarui profil: " . mysqli_error($conn);
    }
}

echo json_encode($response);
mysqli_close($conn);
?>