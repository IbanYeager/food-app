<?php
include "config.php";

header('Content-Type: application/json');

// ambil parameter dari request (default page=1, limit=10)
$page  = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
$offset = ($page - 1) * $limit;

// hitung total data
$totalResult = mysqli_query($conn, "SELECT COUNT(*) as total FROM menus");
$totalRow = mysqli_fetch_assoc($totalResult);
$totalData = (int)$totalRow['total'];

// query data dengan limit + offset
$result = mysqli_query($conn, "SELECT * FROM menus LIMIT $limit OFFSET $offset");

$menus = [];
while ($row = mysqli_fetch_assoc($result)) {
    // tambahkan base url ke gambar biar bisa diakses Flutter
    $row['gambar'] = "http://192.168.1.9/test_application/assets/images/" . $row['gambar'];
    $menus[] = $row;
}

// apakah masih ada halaman berikutnya?
$hasMore = ($page * $limit) < $totalData;

// response JSON
$response = [
    "page" => $page,
    "limit" => $limit,
    "total" => $totalData,
    "hasMore" => $hasMore,
    "data" => $menus
];

echo json_encode($response);
?>