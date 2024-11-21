import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100, // Light background for the screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading Icon
            const CircularProgressIndicator(
              color: Colors.blue, // Optional customization of spinner color
            ),
            const SizedBox(height: 20), // Space between spinner and message
            // Error Message
            Text(
              'Internal Server Error 500',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700, // Error message color
              ),
            ),

],
        ),
      ),
    );
  }
}
