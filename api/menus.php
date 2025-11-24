<?php
include "config.php"; // Pastikan koneksi DB Anda ada di sini

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Fungsi untuk response error yang konsisten
function send_error($message) {
    http_response_code(500); // Internal Server Error
    echo json_encode(["error" => $message]);
    exit();
}

// 1. Ambil dan validasi parameter dari GET request
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$category = isset($_GET['kategori']) ? $_GET['kategori'] : null;
$is_promo = isset($_GET['promo']) && $_GET['promo'] == '1';

$offset = ($page - 1) * $limit;

// 2. Bangun query menggunakan Prepared Statements untuk keamanan
$base_query = " FROM menus";
$where_clauses = [];
$params = []; // Array untuk menampung nilai parameter
$types = "";  // String untuk tipe data parameter (s = string, i = integer)

// Logika filter agar bisa digabung (misal: promo + kategori)
if ($is_promo) {
    $where_clauses[] = "is_promo = ?";
    $params[] = 1;
    $types .= "i";
}

if ($category) {
    $where_clauses[] = "kategori = ?";
    $params[] = $category;
    $types .= "s";
}

$where_sql = "";
if (count($where_clauses) > 0) {
    $where_sql = " WHERE " . implode(" AND ", $where_clauses);
}

// 3. Query untuk mengambil total data
$total_query = "SELECT COUNT(id) AS total" . $base_query . $where_sql;
$stmt_total = mysqli_prepare($conn, $total_query);
if (!$stmt_total) {
    send_error("Gagal mempersiapkan query total: " . mysqli_error($conn));
}

if (count($params) > 0) {
    mysqli_stmt_bind_param($stmt_total, $types, ...$params);
}

mysqli_stmt_execute($stmt_total);
$total_result = mysqli_stmt_get_result($stmt_total);
$total_row = mysqli_fetch_assoc($total_result);
$total_items = $total_row ? $total_row['total'] : 0;
mysqli_stmt_close($stmt_total);

// 4. Query utama dengan LIMIT dan OFFSET
$query = "SELECT * " . $base_query . $where_sql . " LIMIT ? OFFSET ?";
$stmt_main = mysqli_prepare($conn, $query);
if (!$stmt_main) {
    send_error("Gagal mempersiapkan query utama: " . mysqli_error($conn));
}

// Gabungkan parameter filter dengan parameter pagination
$params_with_paging = $params;
$params_with_paging[] = $limit;
$params_with_paging[] = $offset;
$types_with_paging = $types . "ii"; // ii untuk limit dan offset (integer)

mysqli_stmt_bind_param($stmt_main, $types_with_paging, ...$params_with_paging);
mysqli_stmt_execute($stmt_main);
$result = mysqli_stmt_get_result($stmt_main);

if (!$result) {
    send_error("Gagal mengeksekusi query utama: " . mysqli_stmt_error($stmt_main));
}

$menus = [];
while ($row = mysqli_fetch_assoc($result)) {
    // Bangun URL gambar lengkap jika belum ada
    if ($row['gambar'] && !preg_match('/^http(s)?:\/\//', $row['gambar'])) {
        // Ganti IP address sesuai dengan server lokal Anda
        $row['gambar'] = "http://192.168.1.6/test_application/assets/images/" . $row['gambar'];
    }
    $menus[] = $row;
}
mysqli_stmt_close($stmt_main);

// 5. Kirim response JSON yang sudah final
$response = [
    "total_items" => (int)$total_items,
    "current_page" => $page,
    "total_pages" => $limit > 0 ? (int)ceil($total_items / $limit) : 0,
    "data" => $menus
];

echo json_encode($response);
?>