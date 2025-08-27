<?php
$host = "localhost";
$port = 3307;
$user = "root";
$pass = "";
$db   = "resto_db";

$conn = mysqli_connect($host, $user, $pass, $db, $port);

if (!$conn) {
    die("Koneksi gagal: " . mysqli_connect_error());
}
?>
