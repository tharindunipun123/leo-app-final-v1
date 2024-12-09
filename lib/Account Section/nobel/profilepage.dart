import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:leo_app_01/Account%20Section/level/question.dart';
import 'package:leo_app_01/Account%20Section/nobel/nobelcart.dart';
import 'package:leo_app_01/Account%20Section/nobel/rankingpage.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

class profilepage extends StatefulWidget {
  String ID;
  profilepage({required this.ID, super.key, required String userId});

  @override
  State<profilepage> createState() => _profilepageState();
}

class _profilepageState extends State<profilepage> {
  // List<databases>? Databases;
  // late UserService _userService;
  // late Future<User> _futureUser;
  int databaseid = 2;

  String profile = '';
  String profilepic = '';
  int limit = 0;
  double x = 0;
  int endcount = 999;
  int nextcount = 0;
  String frame = "assetss/nononbel.json";
  double precentage = 0;
  String nobelcon = "assetss/Resizers/nonbarcon.png";
  String nobelback = "assetss/Resizers/nonback.jpg";
  Color barcolor = Colors.white;
  String downbar = "assetss/Resizers/nonbar.png";
  String nobelbatch = "assetss/Resizers/pawnbatch.png";
  String nobelpriveledge = "assetss/Resizers/nonprevelege.png";
  String limitline = "";
  int limitvalue = 0;
  String nobelname = "Non nobel";
  final PocketBase pb = PocketBase('http://145.223.21.62:8090');
  int nobelcount = 0;
  bool isLoading = true;
  String errorMessage = '';
  String name = '';
  String firstName = '';
  @override
  void initState() {
    super.initState();
    fetchAndUpdateNobelCount();
    setupRealTimeSubscription();
    updateCounted();
  }

  Future<void> fetchAndUpdateNobelCount() async {
    try {
      // Fetch user information
      final user = await pb.collection('users').getFirstListItem(
            'id="${widget.ID}"',
          );

      firstName = user.data['firstname'].toString(); // Fetch the first name
      print('User First Name: $firstName');

      // Fetch the user's nobel_count

      // Fetch gift counts for this user as sender
      final giftResult =
          await pb.collection('sending_recieving_gifts').getFullList(
                filter: 'sender_user_id="${widget.ID}"',
              );

      // Check if no gifts exist
      if (giftResult.isEmpty) {
        print('No gifts found for user with ID: ${widget.ID}');
              if (mounted) {

        setState(() {
          isLoading = false;
        });
              }
        return;
      }

      // Sum up the gift counts
      int totalGiftCount = giftResult.fold(0, (sum, item) {
        final giftCount = int.tryParse(item.data['gift_count'].toString()) ?? 0;
        return sum + giftCount;
      });

      // Update the total Nobel count
      if (mounted) {
        setState(() {
          nobelcount = totalGiftCount;
          isLoading = false;
        });
      }
      print('Total Gift Count: $totalGiftCount');
      print('Updated Nobel Count: $nobelcount');
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load data: $error';
          isLoading = false;
        });
      }
      print('Error fetching data: $error');
    }
    sendTextToPrivilegeCollection();
  }

  void setupRealTimeSubscription() {
    pb.collection('sending_recieving_gifts').subscribe('*', (e) {
      if (e.action == 'create' || e.action == 'update') {
        if (e.record!.data['sender_user_id'] == widget.ID) {
          fetchAndUpdateNobelCount(); // Recalculate Nobel count in real-time
        }
      }
    });
  }
Future<void> sendTextToPrivilegeCollection() async {
  String nameitem;

  print('Nobel Count: $nobelcount'); // Debugging output

  // Determine the nameitem based on nobelcount
  if (500 <= nobelcount && nobelcount <= 1499) {
    nameitem = "Pawn";
  } else if (1499 < nobelcount && nobelcount <= 3999) {
    nameitem = "Rook";
  } else if (3999 < nobelcount && nobelcount <= 11999) {
    nameitem = "Knight";
  } else if (11999 < nobelcount && nobelcount <= 29999) {
    nameitem = "Bishop";
  } else if (29999 < nobelcount && nobelcount <= 59999) {
    nameitem = "Queen";
  } else if (59999 < nobelcount && nobelcount <= 149999) {
    nameitem = "Duke";
  } else if (149999 < nobelcount && nobelcount <= 299999) {
    nameitem = "King";
  } else if (299999 < nobelcount && nobelcount <= 449999) {
    nameitem = "SKing";
  } else if (449999 < nobelcount && nobelcount <= 1009999) {
    nameitem = "SSKing";
  } else {
    print('Nobel count does not match any range.');
    return;
  }

try {
  final existingEntry = await pb.collection('privilege').getFirstListItem(
    'UserID = "${widget.ID}" && name = "$nameitem"',
  );

  if (existingEntry != null) {
    print('Entry already exists for UserID: ${widget.ID} and name: $nameitem');
    return;
  }
} catch (e) {
  // Handle the case where no entry exists (404 Not Found)
  if (!e.toString().contains("404")) {
    print('Error checking for existing entry: $e');
    return;
  }
}


  // Define the body for the request
  final Map<String, String> body = {
    'UserID': widget.ID,
    'name': nameitem,
    'frame': '',
    'name_plate': '',
    'badge': '',
    'entry_effect': '',
    'profile_card': '',
  };

  // Add URLs dynamically based on nameitem
  switch (nameitem) {
    case "Pawn":
      body['frame'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/zlzeg3j4a9yoafw/pawn_noble_badge_dpMClKSb9p.PNG?token=";
      body['name_plate'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/zlzeg3j4a9yoafw/pawn_noble_name_plate_nZASF7UNxh.PNG?token=";
      break;
    case "Rook":
      body['frame'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/uf5nu5mw2v0smrm/rook_frame_NDP2cWQR3I.png?token=";
      body['name_plate'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/uf5nu5mw2v0smrm/baron_wuwWQHTQ3f.png?token=";
      body['badge'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/uf5nu5mw2v0smrm/rook_noble_badge_07KVD2z6dB.PNG?token=";
      break;
    case "Knight":
      body['frame'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/9o8tde3cqveuw2z/knight_frame_qEaj79eCIT.png?token=";
      body['name_plate'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/9o8tde3cqveuw2z/knight_noble_badge_name_LkYXJApSE6.PNG?token=";
      body['badge'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/9o8tde3cqveuw2z/knight_noble_badge_rnT7iv97pL.PNG?token=";
      body['entry_effect'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/9o8tde3cqveuw2z/knight_fancy_plate_gtr1C3agVm.png?token=";
      body['profile_card'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/9o8tde3cqveuw2z/knightcard_cwIhCGmYSF.png?token=";
      break;
    case "Bishop":
      body['frame'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/wvs5dcwav28lyao/bishop_frame_J1ZbCRRMkT.png?token=";
      body['name_plate'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/wvs5dcwav28lyao/bishop_noble_badge_name_5GmB9MYzo7.PNG?token=";
      body['badge'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/wvs5dcwav28lyao/bishop_noble_badge_v9Anfyp7kE.PNG?token=";
      body['entry_effect'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/wvs5dcwav28lyao/bishop_fancy_plate_kUCrmfpMH3.png?token=";
      body['profile_card'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/wvs5dcwav28lyao/bishopcard_XiTGMXiirQ.png?token=";
      break;
 case "Queen":
    body['frame'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/queen/frame_Queen.png?token=";
    body['name_plate'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/queen/name_plate_Queen.png?token=";
    body['badge'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/queen/badge_Queen.png?token=";
    body['entry_effect'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/queen/entry_effect_Queen.png?token=";
    body['profile_card'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/queen/profile_card_Queen.png?token=";
    break;
  case "Duke":
    body['frame'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/duke/frame_Duke.png?token=";
    body['name_plate'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/duke/name_plate_Duke.png?token=";
    body['badge'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/duke/badge_Duke.png?token=";
    body['entry_effect'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/duke/entry_effect_Duke.png?token=";
    body['profile_card'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/duke/profile_card_Duke.png?token=";
    break;
  case "King":
    body['frame'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/king/frame_King.png?token=";
    body['name_plate'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/king/name_plate_King.png?token=";
    body['badge'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/king/badge_King.png?token=";
    body['entry_effect'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/king/entry_effect_King.png?token=";
    body['profile_card'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/king/profile_card_King.png?token=";
    break;
  case "SKing":
    body['frame'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/superking/frame_SKing.png?token=";
    body['name_plate'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/superking/name_plate_SKing.png?token=";
    body['badge'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/superking/badge_SKing.png?token=";
    body['entry_effect'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/superking/entry_effect_SKing.png?token=";
    body['profile_card'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/superking/profile_card_SKing.png?token=";
    break;
  case "SSKing":
    body['frame'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/ultraking/frame_SSKing.png?token=";
    body['name_plate'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/ultraking/name_plate_SSKing.png?token=";
    body['badge'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/ultraking/badge_SSKing.png?token=";
    body['entry_effect'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/ultraking/entry_effect_SSKing.png?token=";
    body['profile_card'] = "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/ultraking/profile_card_SSKing.png?token=";
    break;


    // Add other cases for "Queen", "Duke", "King", "SKing", "SSKing"
  }

  // Send the data to PocketBase
  try {
    final response = await pb.collection('privilege').create(body: body);
    print('Message sent to privilege collection: $response');
  } catch (error) {
    print('Error sending message to privilege collection: $error');
  }
}

  @override
  void dispose() {
    pb.collection('sending_recieving_gifts').unsubscribe('*');
    super.dispose();
  }



  void updateCounted() {
    if (mounted) {
      setState(() {
        if (nobelcount < 500) {
          limit = 0;
          x = nobelcount.toDouble() - limit;
          nobelname = "Non Nobel";
          endcount = 500;
          precentage = nobelcount / endcount;
          barcolor = const Color.fromARGB(255, 61, 61, 61);
          nobelcon = "assetss/Resizers/nonbarcon.png";
          downbar = "assetss/Resizers/nonbar.png";
          nobelbatch = "assetss/Resizers/nonbatch.png";
          nobelpriveledge = "assetss/Resizers/nonprevelege.png";
          frame =
              'http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/tzhpei3enhpop7g/bishop_EDTepE711o.json?token=';
          nobelback = "assetss/Resizers/nonback.jpg";
          limitvalue = 0;
          limitline = '';
        }

        //Pawn
        else if (500 <= nobelcount && nobelcount <= 1499) {
          limit = 500;
          x = nobelcount.toDouble() - limit;
          endcount = 1499;
          nextcount = 3999;
          frame =
              'http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/zlzeg3j4a9yoafw/pawn2_Vu56ZpaCN6.json?token=';
          precentage = nobelcount / endcount;
          nobelback = "assetss/Resizers/pawnback.jpg";
          barcolor = const Color.fromARGB(255, 25, 121, 29);
          nobelcon = "assetss/Resizers/barcon.png";
          downbar = "assetss/Resizers/bar.png";
          nobelbatch = "assetss/Resizers/pawnbatch.png";
          nobelpriveledge = "assetss/Resizers/pawnprevelege.png";
          limitline = "749";
          limitvalue = 749;
          nobelname = "Pawan";
        }
        //Rook
        else if (1500 <= nobelcount && nobelcount <= 3999) {
          limit = 1500;
          endcount = 3999;
          nextcount = 11999;
          frame =
              "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/uf5nu5mw2v0smrm/rook_czgrNHkw50.json?token=";
          precentage = nobelcount / endcount;
          nobelback = "assetss/Resizers/rookback.jpg";
          barcolor = const Color.fromARGB(255, 3, 103, 186);
          nobelcon = "assetss/Resizers/rookbarcon.png";
          downbar = "assetss/Resizers/rookbar.png";
          nobelbatch = "assetss/Resizers/rookbatch.png";
          nobelpriveledge = "assetss/Resizers/rookprevelege.png";
          limitline = "2.499K";
          limitvalue = 2499;
          nobelname = "Rook";
        }
        //Knight
        else if (4000 <= nobelcount && nobelcount <= 11999) {
          limit = 4000;
          endcount = 11999;
          endcount = 11999;
          nextcount = 29999;
          frame =
              'http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/9o8tde3cqveuw2z/knight_FdBld82iIb.json?token=';
          precentage = nobelcount / endcount;
          nobelback = "assetss/Resizers/knightback.jpg";
          barcolor = const Color.fromARGB(255, 153, 0, 180);
          nobelcon = "assetss/Resizers/knightbarcon.png";
          downbar = "assetss/Resizers/knightbar.png";
          nobelbatch = "assetss/Resizers/knightbatch.png";
          nobelpriveledge = "assetss/Resizers/knightprevelege.png";
          limitline = "6.999k";
          limitvalue = 6999;
          nobelname = "Knight";
        }
        //Bishop
        else if (12000 <= nobelcount && nobelcount <= 29999) {
          limit = 12000;
          endcount = 29999;
          endcount = 29999;
          nextcount = 59999;
          frame =
              'http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/wvs5dcwav28lyao/bishop2_mcD1BS10w2.json?token=';
          precentage = nobelcount / endcount;
          nobelback = "assetss/Resizers/bishopback.jpg";
          barcolor = Color.fromARGB(255, 101, 11, 68);
          nobelcon = "assetss/Resizers/bishopbarcon.png";
          downbar = "assetss/Resizers/bishopbar.png";
          nobelbatch = "assetss/Resizers/bishopbatch.png";
          nobelpriveledge = "assetss/Resizers/bishopprevelege.png";
          limitline = "16.99k";
          limitvalue = 16999;
          nobelname = "Bishop";
        }
        //Queen
        else if (30000 <= nobelcount && nobelcount <= 59999) {
          limit = 30000;
          endcount = 59999;
          endcount = 59999;
          nextcount = 149999;
          frame =
              'http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/ixrd0aek7ibajo7/queen_MRtAADnvt2.json?token=';
          precentage = nobelcount / endcount;
          nobelback = "assetss/Resizers/queenback.jpg";
          barcolor = Color.fromARGB(255, 177, 114, 6);
          nobelcon = "assetss/Resizers/queenbarcon.png";
          downbar = "assetss/Resizers/queenbar.png";
          nobelbatch = "assetss/Resizers/queenbatch.png";
          nobelpriveledge = "assetss/Resizers/queenprevelege.png";
          limitline = "36.99k";
          limitvalue = 36999;
          nobelname = "Queen";
        }
        //Duke
        else if (60000 <= nobelcount && nobelcount <= 149999) {
          limit = 60000;
          endcount = 149999;
          endcount = 149999;
          nextcount = 299999;
          frame =
              'http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/xz866x6it0v0t5e/duke2_cGjuYWrXWm.json?token=';
          precentage = nobelcount / endcount;
          nobelback = "assetss/Resizers/dukeback.jpg";
          barcolor = Color.fromARGB(255, 170, 173, 2);
          nobelcon = "assetss/Resizers/dukebarcon.png";
          downbar = "assetss/Resizers/dukebar.png";
          nobelbatch = "assetss/Resizers/dukebatch.png";
          nobelpriveledge = "assetss/Resizers/dukeprevelege.png";
          limitline = "69.99k";
          limitvalue = 69999;
          nobelname = "Duke";
        }
        //King
        else if (150000 <= nobelcount && nobelcount <= 299999) {
          limit = 150000;
          endcount = 299999;
          endcount = 299999;
          nextcount = 499999;
          frame =
              'http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/8melvqsy2uyi3qx/king_S5vFa2g9DK.json?token=';
          precentage = nobelcount / endcount;
          nobelback = "assetss/Resizers/kingback.jpg";
          barcolor = Color.fromARGB(255, 110, 19, 5);
          nobelcon = "assetss/Resizers/kingbarcon.png";
          downbar = "assetss/Resizers/kingbar.png";
          nobelbatch = "assetss/Resizers/kingbatch.png";
          nobelpriveledge = "assetss/Resizers/kingprevelege.png";
          limitline = "174.9k";
          limitvalue = 174999;
          nobelname = "King";
        }
        //Sking
        else if (300000 <= nobelcount && nobelcount <= 499999) {
          limit = 300000;
          endcount = 499999;
          endcount = 499999;
          nextcount = 1000000;
          frame =
              'http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/7lo2um0psgwr0sd/sking_UjZ3Kj7H3F.json?token=';
          precentage = nobelcount / endcount;
          nobelback = "assetss/Resizers/skingback.jpg";
          barcolor = Color.fromARGB(255, 80, 3, 76);
          nobelcon = "assetss/Resizers/skingbarcon.png";
          downbar = "assetss/Resizers/skingbar.png";
          nobelbatch = "assetss/Resizers/skingbatch.png";
          nobelpriveledge = "assetss/Resizers/skingprevelege.png";
          limitline = "369.9k";
          limitvalue = 369999;
          nobelname = "SKing";
        }
        //SSking
        else if (500000 <= nobelcount && nobelcount <= 1000000) {
          limit = 500000;
          endcount = 1000000;
          endcount = 1000000;
          nextcount = 12000000;
          frame =
              'http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/pbcuuwmmistu0bq/ssking_eTzOxyIT1T.json?token=';
          precentage = nobelcount / endcount;
          nobelback = "assetss/Resizers/sskingback.jpg";
          barcolor = Color.fromARGB(255, 111, 88, 4);
          nobelcon = "assetss/Resizers/sskingbarcon.png";
          downbar = "assetss/Resizers/sskingbar.png";
          nobelbatch = "assetss/Resizers/sskingbatch.png";
          nobelpriveledge = "assetss/Resizers/sskingprevelege.png";
          limitline = "699.9k";
          limitvalue = 699999;
          nobelname = "SSKing";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    updateCounted();
    setupRealTimeSubscription();
    fetchAndUpdateNobelCount();
//nobelcount=(Provider.of<databasedata>(context,listen: false).Databases[0].count).toDouble();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(nobelback), fit: BoxFit.cover)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.black,
                                  size: width / 18,
                                  shadows: [
                                    BoxShadow(
                                        blurRadius: 30,
                                        blurStyle: BlurStyle.outer,
                                        color: const Color.fromARGB(
                                            255, 68, 68, 68))
                                  ],
                                )),
                            Text(
                              "MY NOBEL",
                              style: TextStyle(
                                  color: Colors.white,
                                  shadows: [
                                    BoxShadow(
                                        blurRadius: 30,
                                        color: Colors.black,
                                        blurStyle: BlurStyle.outer)
                                  ],
                                  fontSize: width / 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: IconButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (context) {
                                        return RankingPage();
                                      },
                                    ));
                                  },
                                  icon: Icon(
                                    FontAwesomeIcons.trophy,
                                    color: Color.fromARGB(255, 255, 200, 0),
                                    size: width / 15,
                                  )),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) {
                                      return question();
                                    },
                                  ));
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: Center(
                                      child: Icon(
                                        Icons.question_mark,
                                        size: width / 25,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          left: width / 20,
                          right: width / 20,
                          bottom: height / 40),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage(nobelcon), fit: BoxFit.fill)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      firstName,
                                      style: TextStyle(
                                          color: Colors.white,
                                          shadows: [
                                            BoxShadow(
                                                blurRadius: 20,
                                                color: Colors.black,
                                                blurStyle: BlurStyle.outer)
                                          ],
                                          fontSize: width / 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                //profile image section
                                if (nobelcount >= 500) ...[
                                  SizedBox(
                                    width: width / 3,
                                    child: LottieBuilder.network(
                                      frame,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                ],

                                if (nobelcount < 500) ...[
                                  SizedBox(
                                    width: width / 3,
                                    height: height / 7,
                                  )
                                ]
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                  top: height / 76, bottom: height / 60),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                    horizontal: width / 30),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.money,
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                            size: width / 25),
                                        Text(
                                          "$limit",
                                          style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 255, 255, 255),
                                              fontSize: width / 25,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      width: width / 100,
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: height / 170,
                                            ),
                                            Container(
                                              width: width / 3,
                                              child: LinearPercentIndicator(
                                                center: Container(
                                                    height: height / 72,
                                                    width: 2,
                                                    color: const Color.fromARGB(
                                                        255, 155, 155, 155)),
                                                lineHeight: height / 70,
                                                animation: true,
                                                progressColor: barcolor,
                                                percent: precentage,
                                                barRadius: Radius.circular(55),
                                                backgroundColor: Color.fromARGB(
                                                    255, 255, 255, 255),
                                              ),
                                            ),
                                            Center(
                                                child: Text(
                                              limitline,
                                              style: TextStyle(
                                                  fontSize: width / 36,
                                                  color: Color.fromARGB(
                                                      255, 252, 252, 252)),
                                            ))
                                          ],
                                        ),
                                        SizedBox(
                                          width: width / 100,
                                        ),
                                        Text(
                                          "$endcount",
                                          style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 255, 255, 255),
                                              fontSize: width / 25,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (limitvalue - nobelcount >= 0 && nobelcount >= 500) ...[
                      Text(
                          "Need ${(limitvalue - nobelcount).toString()} to secure your current"
                          "\n"
                          "nobel level $nobelname",
                          style: TextStyle(
                              fontSize: width / 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [BoxShadow(blurRadius: 2)]),
                          textAlign: TextAlign.center),
                    ],
                    if (nobelcount - limitvalue >= 0 && nobelcount >= 500) ...[
                      Text(
                          "You'll secure your current nobel level $nobelname after validity period"
                          "\n"
                          "To uppgrade to next nobel you need ${(endcount - nobelcount).toString()}",
                          style: TextStyle(
                              fontSize: width / 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [BoxShadow(blurRadius: 2)]),
                          textAlign: TextAlign.center)
                    ],
                  ]),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: width / 40,
                          right: width / 40,
                        ),
                        child: Container(
                          child: SingleChildScrollView(
                            physics: ScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                if ((nobelcount < 500)) ...[
                                  nobelcart(
                                    img: [
                                      "assetss/Resizers/Frame.png",
                                      "assetss/Resizers/Name-Plate.png",
                                    ],
                                    name: 'Non-Nobel',
                                    fcolor: Color.fromARGB(166, 35, 97, 37),
                                    lcolor:
                                        const Color.fromARGB(166, 17, 48, 18),
                                    nobelpreve: nobelpriveledge,
                                    nobelbatch: nobelbatch,
                                    imgname: ["Frame", "NamePlate"],
                                  ),
                                  SizedBox(
                                    width: width / 40,
                                  ),
                                ],
                                if ((nobelcount <= 1499)) ...[
                                  nobelcart(
                                    img: [
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/zlzeg3j4a9yoafw/pawn_noble_badge_dpMClKSb9p.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/zlzeg3j4a9yoafw/pawn_noble_name_plate_nZASF7UNxh.PNG?token=",
                                    ],
                                    name: 'Pawn',
                                    fcolor: Color.fromARGB(166, 35, 97, 37),
                                    lcolor:
                                        const Color.fromARGB(166, 17, 48, 18),
                                    nobelpreve: nobelpriveledge,
                                    nobelbatch: nobelbatch,
                                    imgname: [
                                      "Frame",
                                      "NamePlate",
                                    ],
                                  ),
                                  SizedBox(
                                    width: width / 40,
                                  ),
                                ],
                                if ((nobelcount <= 3999)) ...[
                                  nobelcart(
                                    img: [
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/uf5nu5mw2v0smrm/rook_noble_badge_07KVD2z6dB.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/uf5nu5mw2v0smrm/rook_frame_NDP2cWQR3I.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/uf5nu5mw2v0smrm/baron_wuwWQHTQ3f.png?token=",
                                    ],
                                    name: 'Rook',
                                    fcolor: Color.fromARGB(166, 21, 100, 165),
                                    lcolor: Color.fromARGB(166, 13, 64, 105),
                                    nobelpreve: nobelpriveledge,
                                    nobelbatch: nobelbatch,
                                    imgname: [
                                      "Badge",
                                      "Frame",
                                      "NamePlate",
                                    ],
                                  ),
                                  SizedBox(
                                    width: width / 40,
                                  ),
                                ],
                                if ((nobelcount <= 11999)) ...[
                                  nobelcart(
                                    img: [
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/9o8tde3cqveuw2z/knight_noble_badge_rnT7iv97pL.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/9o8tde3cqveuw2z/knight_frame_qEaj79eCIT.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/9o8tde3cqveuw2z/knight_noble_badge_name_LkYXJApSE6.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/9o8tde3cqveuw2z/knight_fancy_plate_gtr1C3agVm.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/9o8tde3cqveuw2z/knightcard_cwIhCGmYSF.png?token="
                                    ],
                                    name: 'Knight',
                                    fcolor: Color.fromARGB(166, 116, 29, 132),
                                    lcolor: Color.fromARGB(166, 74, 18, 84),
                                    nobelpreve: nobelpriveledge,
                                    nobelbatch: nobelbatch,
                                    imgname: [
                                      "Badge",
                                      "Frame",
                                      "NamePlate",
                                      "Entry Effect",
                                      "Profile Card"
                                    ],
                                  ),
                                  SizedBox(
                                    width: width / 40,
                                  ),
                                ],
                                if ((nobelcount <= 29999)) ...[
                                  nobelcart(
                                    img: [
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/wvs5dcwav28lyao/bishop_noble_badge_v9Anfyp7kE.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/wvs5dcwav28lyao/bishop_frame_J1ZbCRRMkT.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/wvs5dcwav28lyao/bishop_noble_badge_name_5GmB9MYzo7.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/wvs5dcwav28lyao/bishop_fancy_plate_kUCrmfpMH3.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/wvs5dcwav28lyao/bishopcard_XiTGMXiirQ.png?token="
                                    ],
                                    name: 'Bishop',
                                    fcolor: Color.fromARGB(166, 158, 19, 65),
                                    lcolor: Color.fromARGB(166, 83, 10, 34),
                                    nobelpreve: nobelpriveledge,
                                    nobelbatch: nobelbatch,
                                    imgname: [
                                      "Badge",
                                      "Frame",
                                      "NamePlate",
                                      "Entry Effect",
                                      "Profile Card"
                                    ],
                                  ),
                                  SizedBox(
                                    width: width / 40,
                                  ),
                                ],
                                if ((nobelcount <= 59999)) ...[
                                  nobelcart(
                                    img: [
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/ixrd0aek7ibajo7/queen_noble_badge_oUPgLWPyDK.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/ixrd0aek7ibajo7/queen_frame_8p6GVkdEJf.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/ixrd0aek7ibajo7/queen_noble_badge_name_ecDLbCCqcA.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/ixrd0aek7ibajo7/queen_fancy_plate_jyoXEmcTWZ.png?token=g",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/ixrd0aek7ibajo7/queencard_lO21EJLkaM.png?token="
                                    ],
                                    name: 'Queen',
                                    fcolor: Color.fromARGB(166, 110, 66, 1),
                                    lcolor: Color.fromARGB(166, 55, 33, 0),
                                    nobelpreve: nobelpriveledge,
                                    nobelbatch: nobelbatch,
                                    imgname: [
                                      "Badge",
                                      "Frame",
                                      "NamePlate",
                                      "Entry Effect",
                                      "Profile Card"
                                    ],
                                  ),
                                  SizedBox(
                                    width: width / 40,
                                  ),
                                ],
                                if ((nobelcount <= 149999)) ...[
                                  nobelcart(
                                    img: [
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/xz866x6it0v0t5e/duke_noble_badge_weJweXzIOq.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/xz866x6it0v0t5e/duke_frame_ltCEqjyXdu.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/xz866x6it0v0t5e/duke_noble_badge_name_x7ek4TBpqz.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/xz866x6it0v0t5e/duke_fancy_plate_Gqt82tBUmr.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/xz866x6it0v0t5e/dukecard_WPF6tJv9Eo.png?token="
                                    ],
                                    name: 'Duke',
                                    fcolor: Color.fromARGB(166, 207, 186, 0),
                                    lcolor: Color.fromARGB(166, 125, 113, 0),
                                    nobelpreve: nobelpriveledge,
                                    nobelbatch: nobelbatch,
                                    imgname: [
                                      "Badge",
                                      "Frame",
                                      "NamePlate",
                                      "Entry Effect",
                                      "Profile Card"
                                    ],
                                  ),
                                  SizedBox(
                                    width: width / 40,
                                  ),
                                ],
                                if ((nobelcount <= 299999)) ...[
                                  nobelcart(
                                    img: [
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/8melvqsy2uyi3qx/king_noble_badge_yTuO6917AY.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/8melvqsy2uyi3qx/king_frame_IIprUU8O3N.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/8melvqsy2uyi3qx/king_noble_badge_name_ZPO9FlgoQk.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/8melvqsy2uyi3qx/king_fancy_plate_nYWgZjqA8K.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/8melvqsy2uyi3qx/kingcard_qoCmuMRh3p.png?token="
                                    ],
                                    name: 'King',
                                    fcolor: Color.fromARGB(166, 170, 46, 37),
                                    lcolor: Color.fromARGB(166, 83, 22, 17),
                                    nobelpreve: nobelpriveledge,
                                    nobelbatch: nobelbatch,
                                    imgname: [
                                      "Badge",
                                      "Frame",
                                      "NamePlate",
                                      "Entry Effect",
                                      "Profile Card"
                                    ],
                                  ),
                                  SizedBox(
                                    width: width / 40,
                                  ),
                                ],
                                if ((nobelcount <= 449999)) ...[
                                  nobelcart(
                                    img: [
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/7lo2um0psgwr0sd/sking_noble_badge_Y2LSjwz4Vg.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/7lo2um0psgwr0sd/sking_frame_oV7CMHAqUc.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/7lo2um0psgwr0sd/sking_noble_badge_name_sTxQJ4cFN5.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/7lo2um0psgwr0sd/sking_fancy_plate_A26pIwOSQg.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/7lo2um0psgwr0sd/skingcard_ipMN3neILV.png?token="
                                    ],
                                    name: 'SKing',
                                    fcolor: Color.fromARGB(166, 65, 1, 61),
                                    lcolor: Color.fromARGB(166, 23, 0, 21),
                                    nobelpreve: nobelpriveledge,
                                    nobelbatch: nobelbatch,
                                    imgname: [
                                      "Badge",
                                      "Frame",
                                      "NamePlate",
                                      "Entry Effect",
                                      "Profile Card"
                                    ],
                                  ),
                                  SizedBox(
                                    width: width / 40,
                                  ),
                                ],
                                if ((nobelcount <= 1009999)) ...[
                                  nobelcart(
                                    img: [
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/pbcuuwmmistu0bq/ssking_noble_badge_idklQx2r9U.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/pbcuuwmmistu0bq/ssking_frame_sF4BHLqH6E.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/pbcuuwmmistu0bq/ssking_noble_badge_name_lBL80Sjjcj.PNG?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/pbcuuwmmistu0bq/ssking_fancy_plate_stjWhV55sG.png?token=",
                                      "http://145.223.21.62:8090/api/files/vnhwix61fv2fpio/pbcuuwmmistu0bq/sskingcard_5Ve03tASZT.png?token="
                                    ],
                                    name: 'SSKing',
                                    fcolor: Color.fromARGB(166, 73, 60, 10),
                                    lcolor: Color.fromARGB(166, 36, 30, 5),
                                    nobelpreve: nobelpriveledge,
                                    nobelbatch: nobelbatch,
                                    imgname: [
                                      "Badge",
                                      "Frame",
                                      "NamePlate",
                                      "Entry Effect",
                                      "Profile Card"
                                    ],
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: height / 12,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage(downbar), fit: BoxFit.fill),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
