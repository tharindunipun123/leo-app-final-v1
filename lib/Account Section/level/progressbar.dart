
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rankingpage/statemanegemnt/fillcount.dart';
import 'package:pocketbase/pocketbase.dart';

class ProgressBar extends StatefulWidget {
  String ID;
  ProgressBar({required this.ID, super.key});
  _ProgressBarState createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar> {
  double _progress = 0.0;
  double _fill = 0.0;
  int count = 0;
  int timeggetting = 0;
  int want = 0;
  String dot = "assetss/images/bronzedot.png";
  Color progresscolour = const Color.fromARGB(255, 203, 139, 108);
  final PocketBase pb = PocketBase('http://145.223.21.62:8090');
  bool isLoading = true;
  String errorMessage = '';
  String name = '';
  String firstName = '';
  // @override
  // void initState() {
  // super.initState();
  // WidgetsBinding.instance.addPostFrameCallback((_) {
  // _fetchAndAddTime();
  // });
  // }
//
  // void _fetchAndAddTime() async {
  // try {
  //
  //  int minutes = await apiService.getMinutesById(widget.ID);
//
// setState(()  {
  //
//  int fetchedMinutes = minutes;
//  print(fetchedMinutes);
//  timeggetting = fetchedMinutes;
//  _addTime(fetchedMinutes);
// });
  //
  //
  //
  //
  //  }  catch (e) {
// print("Error fetching minutes: $e");
  //
  //  }
  // }
//

  @override
  void initState() {
    super.initState();
    fetchAndUpdateNobelCount();
    setupRealTimeSubscription();
  }

Future<void> fetchAndUpdateNobelCount() async {
  try {
    // Fetch user information
    final user = await pb.collection('users').getFirstListItem(
      'id="${widget.ID}"',
    );
    firstName = user.data['firstname'].toString(); // Fetch the first name
    print('User First Name: $firstName');

    // Fetch all records for the user in the level_Timer collection
    final giftResult = await pb.collection('level_Timer').getFullList(
      filter: 'UserID="${widget.ID}"',
    );

    // Check if no records exist
    if (giftResult.isEmpty) {
      print('No records found for user with ID: ${widget.ID}');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    // Group records by date and calculate daily totalGiftCount
    Map<String, int> dailyTotals = {};

    for (var item in giftResult) {
      // Fetch Start_Time and End_Time
      final String startTimeString = item.data['Start_Time'] ?? '';
      final String endTimeString = item.data['End_Time'] ?? '';

      if (startTimeString.isEmpty || endTimeString.isEmpty) {
        print("Missing Start_Time or End_Time for record.");
        continue; // Skip this record
      }

      try {
        // Parse Start_Time and End_Time
        final DateTime startTime = DateTime.parse(startTimeString).toUtc();
        final DateTime endTime = DateTime.parse(endTimeString).toUtc();

        // Extract the date (in UTC) for grouping
        final String dateKey = startTime.toIso8601String().split('T').first;

        // Calculate the difference in minutes
        final int differenceInMinutes = endTime.difference(startTime).inMinutes;

        // Add the difference to the appropriate date group
        dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + differenceInMinutes;
      } catch (e) {
        print("Error parsing times for record: $e");
        continue; // Skip this record
      }
    }

    // Calculate the capped totalGiftCount
    int totalGiftCount = dailyTotals.entries.fold(0, (sum, entry) {
      final int dailyTotal = entry.value;
      final int cappedValue = dailyTotal > 300 ? 300 : dailyTotal; // Cap at 300
      print("Date: ${entry.key}, Daily Total: $dailyTotal, Capped Value: $cappedValue");
      return sum + cappedValue;
    });

    // Update the state
    if (mounted) {
      setState(() {
        timeggetting = totalGiftCount; // Store the total capped gift count
        isLoading = false;
        _addTime(totalGiftCount); // Perform any additional operations
      });
    }

    print('Final Total Gift Count (capped daily): $totalGiftCount');
  } catch (error) {
    if (mounted) {
      setState(() {
        errorMessage = 'Failed to load data: $error';
        isLoading = false;
      });
    }
    print('Error fetching data: $error');
  }
}


  void setupRealTimeSubscription() {
    pb.collection('level_Timer').subscribe('*', (e) {
      if (e.action == 'create' || e.action == 'update') {
        if (e.record!.data['UserID'] == widget.ID) {
          fetchAndUpdateNobelCount(); // Recalculate Nobel count in real-time
        }
      }
    });
  }

  void _addTime(int minutes) {
    if (0 <= minutes && minutes < 210) {
      dot = "assetss/images/bronzedot.png";
      progresscolour = Color.fromARGB(255, 203, 139, 108);
      if (minutes >= 0 && minutes < 20) {
        want = 20 - timeggetting;
        count = 0;
      } else if (minutes >= 20 && minutes < 35) {
        want = 35 - timeggetting;
        count = 1;
      } else if (minutes >= 35 && minutes < 45) {
        want = 45 - timeggetting;
        count = 2;
      } else if (minutes >= 45 && minutes < 60) {
        want = 60 - timeggetting;
        count = 3;
      } else if (minutes >= 60 && minutes < 75) {
        want = 75 - timeggetting;
        count = 4;
      } else if (minutes >= 75 && minutes < 90) {
        want = 90 - timeggetting;
        count = 5;
      } else if (minutes >= 90 && minutes < 105) {
        want = 105 - timeggetting;
        count = 6;
      } else if (minutes >= 105 && minutes < 120) {
        want = 120 - timeggetting;
        count = 7;
      } else if (minutes >= 120 && minutes < 150) {
        want = 150 - timeggetting;
        count = 8;
      } else if (minutes >= 150 && minutes < 180) {
        want = 180 - timeggetting;
        count = 9;
      } else if (minutes >= 180 && minutes < 210) {
        want = 210 - timeggetting;
        count = 10;
      }
    } else if (4650 <= minutes) {
      dot = "assetss/images/diamonddot.png";
      progresscolour = Color.fromARGB(255, 188, 171, 216);
      if (minutes >= 4650 && minutes < 4950) {
        want = -timeggetting + 4950;
        count = 1;
      } else if (minutes >= 4950 && minutes < 5250) {
        want = -timeggetting + 5250;
        count = 2;
      } else if (minutes >= 5250 && minutes < 5550) {
        count = 3;
        want = -timeggetting + 5550;
      } else if (minutes >= 5550 && minutes < 5850) {
        want = -timeggetting + 5850;
        count = 4;
      } else if (minutes >= 5850 && minutes < 6150) {
        want = -timeggetting + 6150;
        count = 5;
      } else if (minutes >= 6150 && minutes < 6450) {
        want = -timeggetting + 6450;
        count = 6;
      } else if (minutes >= 6450 && minutes < 6750) {
        want = -timeggetting + 6750;
        count = 7;
      } else if (minutes >= 6750 && minutes < 7050) {
        want = -timeggetting + 7050;
        count = 8;
      } else if (minutes >= 7050 && minutes < 7350) {
        want = -timeggetting + 7350;
        count = 9;
      } else if (minutes >= 7350) {
        want = 0;
        count = 10;
      }
    } else if (210 <= minutes && minutes < 810) {
      dot = "assetss/images/silverdot.png";
      progresscolour = Color.fromARGB(255, 186, 221, 230);
      if (minutes >= 210 && minutes < 240) {
        want = 240 - timeggetting;
        count = 1;
      } else if (minutes >= 240 && minutes < 270) {
        want = 270 - timeggetting;
        count = 2;
      } else if (minutes >= 270 && minutes < 300) {
        want = 300 - timeggetting;
        count = 3;
      } else if (minutes >= 300 && minutes < 330) {
        want = 330 - timeggetting;
        count = 4;
      } else if (minutes >= 330 && minutes < 360) {
        want = 360 - timeggetting;
        count = 5;
      } else if (minutes >= 360 && minutes < 450) {
        want = 450 - timeggetting;
        count = 6;
      } else if (minutes >= 450 && minutes < 540) {
        want = 540 - timeggetting;
        count = 7;
      } else if (minutes >= 540 && minutes < 630) {
        want = 630 - timeggetting;
        count = 8;
      } else if (minutes >= 630 && minutes < 720) {
        want = 720 - timeggetting;
        count = 9;
      } else if (minutes >= 720 && minutes < 810) {
        want = 810 - timeggetting;
        count = 10;
      }
    } else if (810 <= minutes && minutes < 2100) {
      dot = "assetss/images/golddot.png";
      progresscolour = Color.fromARGB(255, 234, 209, 123);

      if (minutes >= 810 && minutes < 900) {
        want = 210 - timeggetting;
        count = 1;
      } else if (minutes >= 900 && minutes < 990) {
        want = 900 - timeggetting;
        count = 2;
      } else if (minutes >= 990 && minutes < 1080) {
        want = 1080 - timeggetting;
        count = 3;
      } else if (minutes >= 1080 && minutes < 1215) {
        want = 1215 - timeggetting;
        count = 4;
      } else if (minutes >= 1215 && minutes < 1350) {
        want = 1350 - timeggetting;
        count = 5;
      } else if (minutes >= 1350 && minutes < 1485) {
        want = 1485 - timeggetting;
        count = 6;
      } else if (minutes >= 1485 && minutes < 1620) {
        want = 1620 - timeggetting;
        count = 7;
      } else if (minutes >= 1620 && minutes < 1755) {
        want = 1755 - timeggetting;
        count = 8;
      } else if (minutes >= 1755 && minutes < 1890) {
        want = 1890 - timeggetting;
        count = 9;
      } else if (minutes >= 1890 && minutes < 2100) {
        want = 2100 - timeggetting;
        count = 10;
      }
    } else if (2100 <= minutes && minutes < 4650) {
      dot = "assetss/images/platinumdot.png";
      progresscolour = Color.fromARGB(255, 208, 198, 166);
      if (minutes >= 2100 && minutes < 2350) {
        want = timeggetting - 2350;

        count = 1;
      } else if (minutes >= 2350 && minutes < 2600) {
        want = 2600 - timeggetting;

        count = 2;
      } else if (minutes >= 2600 && minutes < 2850) {
        want = 2850 - timeggetting;

        count = 3;
      } else if (minutes >= 2850 && minutes < 3050) {
        want = 3050 - timeggetting;

        count = 4;
      } else if (minutes >= 3050 && minutes < 3300) {
        want = 3300 - timeggetting;

        count = 5;
      } else if (minutes >= 3300 && minutes < 3550) {
        want = 3550 - timeggetting;
        count = 6;
      } else if (minutes >= 3550 && minutes < 3800) {
        want = 3800 - timeggetting;
        count = 7;
      } else if (minutes >= 3800 && minutes < 4050) {
        want = 4050 - timeggetting;
        count = 8;
      } else if (minutes >= 4050 && minutes < 4350) {
        want = 4350 - timeggetting;
        count = 9;
      } else if (minutes >= 4350 && minutes < 4650) {
        want = 4650 - timeggetting;
        count = 10;
      }
    }

    _progress = count / 10.0;
    _fill = count / 11.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Provider.of<fillcount>(context, listen: false).updateFillCount(count);
          // Provider.of<fillcount>(context, listen: false)
              // .updateFetchedMinutes(timeggetting);
          // Provider.of<fillcount>(context, listen: false).updatewantcount(want);

  fillCount.updateFillCount(count);
                fillCount.updateFetchedMinutes(timeggetting);
                fillCount.updateWantCount(want);

        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // _fetchAndAddTime();
    setupRealTimeSubscription();
    fetchAndUpdateNobelCount();
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: (screenWidth * _fill) + 1),
          child: Container(
            width: 42,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: count == 0
                    ? BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                      )
                    : BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      )),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                child: Text(
                  timeggetting.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 5,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              LinearProgressIndicator(
                value: _progress,
                minHeight: 6.0,
                borderRadius: BorderRadius.circular(15),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(progresscolour),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
