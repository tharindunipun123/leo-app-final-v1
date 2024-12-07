import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class CountdownScreen extends StatefulWidget {
  @override
  _CountdownScreenState createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  final PocketBase pb = PocketBase('http://145.223.21.62:8090');
  Timer? timer;
  int days = 0;
  int hours = 0;
  int minutes = 0;

  @override
  void initState() {
    super.initState();
    fetchCountdown(); // Fetch countdown timer from PocketBase
    setupPeriodicRefresh(); // Refresh every minute
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  // Fetch the timer data from PocketBase
  Future<void> fetchCountdown() async {
    try {
      // Fetch the timer record with a filter
      final response = await pb.collection('timers').getList(
        filter: 'name = "countdown_timer"',
        perPage: 1,
      );

      if (response.items.isNotEmpty) {
        final record = response.items.first; // Get the first record
        print('Fetched record: ${record.data}');

        // Parse endTime as UTC
        DateTime endTime = DateTime.parse(record.data['endTime']).toUtc();
        print('Parsed End Time (UTC): $endTime');

        // Get current time in UTC
        DateTime now = DateTime.now().toUtc();
        print('Current Time (UTC): $now');

        Duration difference = endTime.difference(now);
        print('Time Difference: $difference');

        if (difference.isNegative) {
          print('Timer expired. Resetting...');
          resetTimer(); // Reset the timer if it has ended
        } else {
            if (mounted) {

            
          
          setState(() {
            days = difference.inDays;
            hours = difference.inHours % 24;
            minutes = difference.inMinutes % 60;
          });
          }
          print('Updated countdown: $days days, $hours hours, $minutes minutes');
        }
      } else {
        print('No countdown timer found.');
      }
    } catch (e) {
      print('Error fetching countdown: $e');
    }
  }

  // Set up periodic refresh for the countdown timer
  void setupPeriodicRefresh() {
  timer = Timer.periodic(Duration(minutes: 1), (Timer t) {
    if (mounted) {
      fetchCountdown(); // Only fetch and update if the widget is still mounted
    }
  });
}

  // Reset the timer in PocketBase (7 days from now)
  Future<void> resetTimer() async {
    try {
      // Fetch the timer record
      final response = await pb.collection('timers').getList(
        filter: 'name = "countdown_timer"',
        perPage: 1,
      );

      if (response.items.isNotEmpty) {
        final record = response.items.first;
        DateTime newEndTime = DateTime.now().toUtc().add(Duration(days: 7));

        // Update the endTime
        await pb.collection('timers').update(record.id, body: {
          "endTime": newEndTime.toIso8601String(),
        });

        print('Timer reset successfully');
        fetchCountdown(); // Refresh the timer
      } else {
        throw Exception('Countdown timer not found in PocketBase');
      }
    } catch (e) {
      print('Error resetting timer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
 fetchCountdown(); // Fetch countdown timer from PocketBase
 setupPeriodicRefresh(); // Refresh every minute
  
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
                          color: Color.fromARGB(255, 68, 35, 0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "0$days",
                            style: TextStyle(
                              fontSize: width / 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        "Days",
                        style: TextStyle(
                          color: Color.fromARGB(255, 68, 35, 0),
                          fontSize: width / 30,
                          fontWeight: FontWeight.bold,
                        ),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: height / 38),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [BoxShadow(blurRadius: 5)],
                          color: Color.fromARGB(255, 68, 35, 0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "$hours",
                            style: TextStyle(
                              fontSize: width / 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        "Hours",
                        style: TextStyle(
                          color: Color.fromARGB(255, 68, 35, 0),
                          fontSize: width / 30,
                          fontWeight: FontWeight.bold,
                        ),
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: height / 38),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [BoxShadow(blurRadius: 5)],
                          color: Color.fromARGB(255, 68, 35, 0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "$minutes",
                            style: TextStyle(
                              fontSize: width / 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        "Minutes",
                        style: TextStyle(
                          color: Color.fromARGB(255, 68, 35, 0),
                          fontSize: width / 30,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
