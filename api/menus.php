<?php
include "config.php";

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // Optional, jika butuh akses dari luar

// 1. Ambil parameter dari GET request
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$category = isset($_GET['kategori']) ? $_GET['kategori'] : null;
$is_promo = isset($_GET['promo']) && $_GET['promo'] == '1' ? true : false;

$offset = ($page - 1) * $limit;

// 2. Bangun query dasar dan klausa WHERE secara dinamis untuk keamanan
$base_query = " FROM menus";
$where_clauses = [];

if ($is_promo) {
    // Jika filter promo aktif, hanya cari yang promo
    $where_clauses[] = "is_promo = 1";
} else if ($category) {
    // Jika tidak ada filter promo, baru cek filter kategori
    // Gunakan mysqli_real_escape_string untuk mencegah SQL Injection
    $safe_category = mysqli_real_escape_string($conn, $category);
    $where_clauses[] = "kategori = '$safe_category'";
}

$where_sql = "";
if (count($where_clauses) > 0) {
    $where_sql = " WHERE " . implode(" AND ", $where_clauses);
}

// 3. Query untuk mengambil total data (sesuai filter yang aktif)
$total_query = "SELECT COUNT(id) AS total" . $base_query . $where_sql;
$total_result = mysqli_query($conn, $total_query);
$total_row = mysqli_fetch_assoc($total_result);
$total_items = $total_row['total'];

// 4. Query utama dengan LIMIT dan OFFSET (sesuai filter yang aktif)
$query = "SELECT * " . $base_query . $where_sql . " LIMIT $limit OFFSET $offset";
$result = mysqli_query($conn, $query);

$menus = [];
while ($row = mysqli_fetch_assoc($result)) {
    // Sesuaikan base URL gambar jika diperlukan
    if ($row['gambar'] && !preg_match('/^http(s)?:\/\//', $row['gambar'])) {
        $row['gambar'] = "http://192.168.1.6/test_application/assets/images/" . $row['gambar'];
    }
    $menus[] = $row;
}

// 5. Response JSON yang informatif
$response = [
    "total_items" => (int)$total_items,
    "current_page" => $page,
    "total_pages" => $limit > 0 ? ceil($total_items / $limit) : 0,
    "data" => $menus
];

echo json_encode($response);
?>