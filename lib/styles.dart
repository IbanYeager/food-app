import 'package:flutter/material.dart';

class AppColors {
  static const darkGray = Color.fromARGB(255, 107, 107, 107);
  static const darktYellow = Color(0XFFF3C623);
}

class TextStyles {
  static TextStyle title = const TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.bold,
    fontSize: 28.0,
    color: Color(0XFFC57E1B),
  );

  static TextStyle body = const TextStyle(
    fontFamily: 'Poppins',
    fontWeight: FontWeight.normal,
    fontSize: 16.0,
    color: AppColors.darkGray,
  );
}