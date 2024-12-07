import 'dart:async';
import 'package:flutter/material.dart';
import 'package:leo_app_01/Account%20Section/nobel/countdown.dart';
import 'package:leo_app_01/Account%20Section/nobel/rankincontainer.dart';
import 'package:pocketbase/pocketbase.dart';
final PocketBase pb = PocketBase('http://145.223.21.62:8090');

class NobelCount {
  final String userId;
  final String name;
  final int nobelCount;

  NobelCount({
    required this.userId,
    required this.name,
    required this.nobelCount,
  });
}
class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  String? topItemName;
  int? topItemCount;
  Timer? _timer;
  List<NobelCount> nobelCounts = [];

  final PocketBase pb = PocketBase('http://145.223.21.62:8090');
  bool isLoading = true;
  String errorMessage = '';


 @override
  void initState() {
    super.initState();
    fetchAndCalculateNobelCounts();
    setupRealTimeSubscription();
    _fetchDataPeriodically();
  }

  Future<void> fetchAndCalculateNobelCounts() async {
    try {
      // Fetch all users
      final usersResponse = await pb.collection('users').getFullList();

      // Prepare Nobel count data dynamically
      List<NobelCount> calculatedNobelCounts = [];

      for (var user in usersResponse) {
        final userId = user.id;
        final userName = user.data['firstname'];

        // Fetch gift counts for this user as sender
        final giftsResponse = await pb.collection('sending_recieving_gifts')
            .getFullList(filter: 'sender_user_id="$userId"');

        // Calculate total gift count
        int totalGiftCount = giftsResponse.fold(0, (sum, item) {
          final giftCount = int.tryParse(item.data['gift_count'].toString()) ?? 0;
          return sum + giftCount;
        });

        // Add to list
        calculatedNobelCounts.add(
          NobelCount(userId: userId, name: userName, nobelCount: totalGiftCount),
        );
      }

      // Sort Nobel counts in descending order
      calculatedNobelCounts.sort((a, b) => b.nobelCount.compareTo(a.nobelCount));

      setState(() {
        nobelCounts = calculatedNobelCounts;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = 'Failed to fetch and calculate Nobel counts: $error';
        isLoading = false;
      });
      print('Error: $error');
    }
  }

  void setupRealTimeSubscription() {
    pb.collection('sending_recieving_gifts').subscribe('*', (e) {
      fetchAndCalculateNobelCounts(); // Re-fetch Nobel counts when data changes
    });
  }

  void _fetchDataPeriodically() {
    // Fetch data every 5 seconds
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchAndCalculateNobelCounts();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    pb.collection('sending_recieving_gifts').unsubscribe('*');
    super.dispose();
  }




  // Future<void> fetchAndSortData() async {
    // try {
      // final response =
          // await pb.collection('nobel_count').getList(sort: '-nobel_count');
      // setState(() {
        // nobelCounts = response.items
            // .map((item) => NobelCount(
                  // userId: item.data['userId'],
                  // nobelCount: item.data['nobel_count'],
                // ))
            // .toList();
        // isLoading = false;
      // });
    // } catch (error) {
      // setState(() {
        // errorMessage = 'Failed to fetch data: $error';
        // isLoading = false;
      // });
    // }
  // }
// 
  // void setupRealTimeSubscription() {
    // pb.collection('nobel_count').subscribe('*', (e) {
      // fetchAndSortData(); // Re-fetch the sorted list on updates
    // });
  // }
// 
  // @override
  // void initState() {
    // super.initState();
    // fetchAndSortData();
    // setupRealTimeSubscription();
    // _fetchDataPeriodically();
    // fetchAllNobelCounts();
  // }
// 
  // void _fetchDataPeriodically() {
    // fetchAllNobelCounts();
// 
    // _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      // fetchAllNobelCounts();
    // });
  // }
// 
  void _handleCountdownEnd() {
    if (nobelCounts.isNotEmpty) {
      setState(() {
        topItemCount = nobelCounts[1].nobelCount;
        topItemName = "Chanuka";
      });
    }
  }
// 
  // @override
  // void dispose() {
    // _timer?.cancel();
    // pb.collection('nobel_count').unsubscribe('*');
    // super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    fetchAndCalculateNobelCounts();
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: Container(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: height / 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: NetworkImage(
                                "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/en1lv8zzi7anj15/noble_interface_2_copy_QKV8Rtd0Hg.png?token="),
                            fit: BoxFit.fill)),
                  ),
                  Container(
                    height: height / 1.4,
                    width: double.infinity,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  )
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: height / 4.3),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        child: CountdownScreen(
                           ),
                        width: double.infinity,
                        height: height / 10,
                        decoration: BoxDecoration(
                            color: Color.fromARGB(255, 240, 240, 240),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20))),
                      ),
                      if (topItemName != null && topItemCount != null) ...[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Top Item: $topItemName, Count: $topItemCount',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      Container(
                        width: double.infinity,
                        height: height / 1.5,
                        child: ListView.builder(
                          itemCount: nobelCounts.length,
                          itemBuilder: (context, index) {
        final item = nobelCounts[index];

                            Widget leadingWidget;

                            if (index == 0) {
                              leadingWidget = Image.asset(
                                'assetss/Resizers/firstplace.png',
                                scale: width / 50,
                              );
                            } else if (index == 1) {
                              leadingWidget = Image.asset(
                                'assetss/Resizers/secondplace.png',
                                scale: width / 50,
                              );
                            } else if (index == 2) {
                              leadingWidget = Image.asset(
                                'assetss/Resizers/thirdplace.png',
                                scale: width / 50,
                              );
                            } else {
                              leadingWidget = Padding(
                                padding: EdgeInsets.only(
                                    left: width / 25, right: width / 25),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                      fontSize: width / 20,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                ),
                              );
                            }

                            return Padding(
                              padding: EdgeInsets.only(bottom: height / 140),
                              child: rankingcontainer(
                                name: item.name, // Add this line
                                nobelcount: item.nobelCount.toString(),
                                leadingget: leadingWidget,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
