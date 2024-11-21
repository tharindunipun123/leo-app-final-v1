import 'package:flutter/material.dart';
import 'Auth/PhoneNumberScreen.dart';

class StartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00F5D4),  // Bright turquoise
              Color(0xFF0086FF),],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/chat.png', // Replace with your image
                      width: 300,
                      height: 300,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Text(
                      'Welcome to Leo Chat',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Connect with friends and family securely',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.teal[700], backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhoneNumberScreen()
                          ),
                        );
                      },
                      child: Text(
                        'Get Started',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '© 2024 Leo Chat',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
