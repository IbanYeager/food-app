<?php
include "config.php";

$email = $_POST['email'];
$password = $_POST['password'];

$sql = "SELECT * FROM users WHERE email='$email' AND password='$password'";
$result = mysqli_query($conn, $sql);

if (mysqli_num_rows($result) > 0) {
    $user = mysqli_fetch_assoc($result);
    echo json_encode([
        "success" => true,
        "message" => "Login berhasil",
        "user" => $user
    ]);
} else {
    echo json_encode([
        "success" => false,
        "message" => "Email atau password salah"
    ]);
}
?>
