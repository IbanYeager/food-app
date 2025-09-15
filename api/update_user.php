<?php
include "config.php";

header('Content-Type: application/json');

// 💡 1. Tentukan base URL untuk gambar Anda. Sesuaikan dengan alamat server Anda.
$base_url = "http://" . $_SERVER['SERVER_NAME'] . dirname($_SERVER['REQUEST_URI']) . "/";
// Jika di-hosting di subfolder, Anda mungkin perlu menyesuaikannya, misal: "http://192.168.1.6/TEST_APPLICATION/api/";

$response = ["status" => "error", "message" => "Metode request tidak valid."];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = $_POST['id'] ?? null;
    $nama = $_POST['nama'] ?? null;
    $email = $_POST['email'] ?? null;
    $no_hp = $_POST['no_hp'] ?? null;

    if ($id === null || $nama === null || $email === null || $no_hp === null) {
        $response['message'] = "Data tidak lengkap.";
        echo json_encode($response);
        exit;
    }

    $foto_path = null;

    if (isset($_FILES['foto']) && $_FILES['foto']['error'] === UPLOAD_ERR_OK) {
        $target_dir = "uploads/";
        if (!is_dir($target_dir)) {
            // Izin 0777 baik untuk development, untuk produksi pertimbangkan 0755
            mkdir($target_dir, 0777, true);
        }

        $file_extension = strtolower(pathinfo($_FILES["foto"]["name"], PATHINFO_EXTENSION));
        $file_name = "user_" . $id . "_" . time() . "." . $file_extension;
        $target_file = $target_dir . $file_name;

        if (move_uploaded_file($_FILES["foto"]["tmp_name"], $target_file)) {
            $foto_path = $target_file; // Simpan path relatif di database
        } else {
            $response['message'] = "Gagal memindahkan file yang diupload. Periksa izin folder 'uploads'.";
            echo json_encode($response);
            exit;
        }
    }

    if ($foto_path) {
        $query = "UPDATE users SET nama = ?, email = ?, no_hp = ?, foto = ? WHERE id = ?";
        $stmt = mysqli_prepare($conn, $query);
        mysqli_stmt_bind_param($stmt, "ssssi", $nama, $email, $no_hp, $foto_path, $id);
    } else {
        $query = "UPDATE users SET nama = ?, email = ?, no_hp = ? WHERE id = ?";
        $stmt = mysqli_prepare($conn, $query);
        mysqli_stmt_bind_param($stmt, "sssi", $nama, $email, $no_hp, $id);
    }

    if (mysqli_stmt_execute($stmt)) {
        mysqli_stmt_close($stmt); // Tutup statement UPDATE sebelum membuat yang baru

        // 💡 2. Gunakan prepared statement untuk SELECT demi keamanan
        $query_select = "SELECT id, nama, email, no_hp, foto FROM users WHERE id = ?";
        $stmt_select = mysqli_prepare($conn, $query_select);
        mysqli_stmt_bind_param($stmt_select, "i", $id);
        mysqli_stmt_execute($stmt_select);
        $result = mysqli_stmt_get_result($stmt_select);
        $user_data = mysqli_fetch_assoc($result);

        // 💡 3. Ubah path relatif menjadi URL lengkap sebelum dikirim ke Flutter
        if ($user_data && !empty($user_data['foto'])) {
            $user_data['foto'] = $base_url . $user_data['foto'];
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