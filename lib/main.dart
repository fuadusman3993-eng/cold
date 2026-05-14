import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'C',
          style: TextStyle(
            color: Colors.white,
            fontSize: 100,
            fontWeight: FontWeight.w900,
            fontFamily: 'Inter',
          ),
        ),
      ),
    ),
  ));
}
