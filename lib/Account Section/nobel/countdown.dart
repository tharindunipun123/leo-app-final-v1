import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CountdownScreen extends StatefulWidget {
  final VoidCallback onCountdownEnd;

  CountdownScreen({required this.onCountdownEnd});

  @override
  _CountdownScreenState createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  int days = 0;
  int hours = 0;
  int minutes = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchCountdown(); // Initial fetch when the widget initializes
    timer = Timer.periodic(Duration(minutes: 1), (Timer t) => fetchCountdown());
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> fetchCountdown() async {
    final response =
        await http.get(Uri.parse('http://172.20.10.2:6060/api/time/countdown'));
    if (response.statusCode == 200) {
      final String countdownFromServer =
          response.body.trim(); // Trim any leading/trailing whitespace

      // Split the string into days, hours, and minutes
      List<String> parts = countdownFromServer.split(' ');
      if (parts.length == 6) {
        setState(() {
          days = int.parse(parts[0]);
          hours = int.parse(parts[2]);
          minutes = int.parse(parts[4]);
        });

        // Check if the countdown has ended
        if (days == 0 && hours == 0 && minutes == 0) {
          widget.onCountdownEnd();
        }
      } else {
        throw Exception('Unexpected countdown format');
      }
    } else {
      throw Exception('Failed to load countdown');
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(left: width / 5, right: width / 5),
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        height: height / 10,
        child: Padding(
          padding: EdgeInsets.only(left: width / 30, right: width / 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            boxShadow: [BoxShadow(blurRadius: 5)],
                            color: Color.fromARGB(255, 68, 35, 0)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "0$days",
                            style: TextStyle(
                                fontSize: width / 16, color: Colors.white),
                          ),
                        ),
                      ),
                      Text(
                        "Day",
                        style: TextStyle(
                            color: Color.fromARGB(255, 68, 35, 0),
                            fontSize: width / 30,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        ":",
                        style: TextStyle(
                            fontSize: width / 10,
                            color: Color.fromARGB(255, 68, 35, 0),
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: height / 38,
                      )
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            boxShadow: [BoxShadow(blurRadius: 5)],
                            color: Color.fromARGB(255, 68, 35, 0)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "$hours",
                            style: TextStyle(
                                fontSize: width / 16, color: Colors.white),
                          ),
                        ),
                      ),
                      Text(
                        "Hours",
                        style: TextStyle(
                            color: Color.fromARGB(255, 68, 35, 0),
                            fontSize: width / 30,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        ":",
                        style: TextStyle(
                            fontSize: width / 10,
                            color: Color.fromARGB(255, 68, 35, 0),
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: height / 38,
                      )
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            boxShadow: [BoxShadow(blurRadius: 5)],
                            color: Color.fromARGB(255, 68, 35, 0)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "$minutes",
                            style: TextStyle(
                                fontSize: width / 16, color: Colors.white),
                          ),
                        ),
                      ),
                      Text(
                        "Min",
                        style: TextStyle(
                            color: Color.fromARGB(255, 68, 35, 0),
                            fontSize: width / 30,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
