import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'Service/database_services.dart';
import 'Service/globals.dart';
import 'Service/userdata.dart';
import 'Service/userservice.dart';
import 'models/database.dart';
import 'models/database_data.dart';
import 'nobelcart.dart';
import 'questionmark.dart';
import 'rankingpage.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'models/database.dart';
import 'package:provider/provider.dart';

class profilepage extends StatefulWidget {
  int ID;
   profilepage({
    
    required this.ID,
    super.key});

  @override
  State<profilepage> createState() => _profilepageState();
}

class _profilepageState extends State<profilepage> {
  List<databases>? Databases;
  late UserService _userService;
  late Future<User> _futureUser;
int databaseid=2;

  String profile = '';
  String profilepic = '';
  double nobelcount = 00;
  int limit = 0;
  String counted = "";
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

  getdata() async {
    Databases = await DatabaseServices.getdata();
    Provider.of<databasedata>(context, listen: false).Databases = Databases!;
    setState(() {});
  }

  Future<double> getNobelCount() async {
    List<databases>? Databases = await DatabaseServices.getdata();
    if (Databases != null && Databases.isNotEmpty && Databases.length >= 2) {
      return Databases[widget.ID].count.toDouble();
    } else {
      // Handle the case where databases is null or empty
      return 0.0; // Or any default value you prefer
    }
  }

  // Future<String> getname() async {
    // List<User>? userDatabases = await UserService(baseUrl:"http://45.126.125.172:8080/api/v1").getUsers();
    // if (userDatabases != null && userDatabases.isNotEmpty && userDatabases.length >= 2) {
      // return userDatabases[2].name.toString();
    // } else {
      // return ''; // Or any default value you prefer
    // }
  // }

  // Future<String> getaddress() async {
    // List<databases>? Databases = await DatabaseServices.getdata();
    // if (Databases != null && Databases.isNotEmpty && Databases.length >= 2) {
      // return Databases[1].address.toString();
    // } else {
      // Handle the case where databases is null or empty
      // return ''; // Or any default value you prefer
    // }
  // }

  @override
  void initState() {
    super.initState();
    getdata();
    updateCounted();
    initializeNobelCount();
   _userService = UserService(baseUrl: 'http://45.126.125.172:8080/api/v1');
   _futureUser = _userService.getUserById(widget.ID); // Fetch user with id = 2  
    // getname();
  }

  void initializeNobelCount() async {
    double count = await getNobelCount();
    // String name = await getname();
    setState(() {
      nobelcount = count;
      // profile=name;
    });
  }

  void updateCounted() {
    setState(() {
      if (nobelcount < 500) {
        limit = 0;
        x = nobelcount - limit;
        nobelname = "Non Nobel";
        endcount = 500;
        precentage = nobelcount / endcount;
        barcolor = const Color.fromARGB(255, 61, 61, 61);
        nobelcon = "assetss/Resizers/nonbarcon.png";
        downbar = "assetss/Resizers/nonbar.png";
        nobelbatch = "assetss/Resizers/nonbatch.png";
        nobelpriveledge = "assetss/Resizers/nonprevelege.png";
        frame = 'assetss/bishop.json';
        nobelback = "assetss/Resizers/nonback.jpg";
        limitvalue = 0;
        limitline = '';
      }

      //Pawn
      else if (500 <= nobelcount && nobelcount <= 1499) {
        counted = "assetss/pawnbatch.png";
        limit = 500;
        x = nobelcount - limit;
        endcount = 1499;
        nextcount = 3999;
        frame = 'assetss/Resizers/pawn2.json';
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
        counted = "assetss/nonnobel.jpg";
        limit = 1500;
        endcount = 3999;
        nextcount = 11999;
        frame = "assetss/Resizers/rook.json";
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
        counted = "assetss/baronbatch.png";
        limit = 4000;
        endcount = 11999;
        endcount = 11999;
        nextcount = 29999;
        frame = 'assetss/Resizers/knight.json';
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
        counted = "assetss/baronbatch.png";
        limit = 12000;
        endcount = 29999;
        endcount = 29999;
        nextcount = 59999;
        frame = 'assetss/Resizers/bishop2.json';
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
        counted = "assetss/baronbatch.png";
        limit = 30000;
        endcount = 59999;
        endcount = 59999;
        nextcount = 149999;
        frame = 'assetss/Resizers/queen.json';
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
        counted = "assetss/baronbatch.png";
        limit = 60000;
        endcount = 149999;
        endcount = 149999;
        nextcount = 299999;
        frame = 'assetss/Resizers/duke2.json';
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
        counted = "assetss/baronbatch.png";
        limit = 150000;
        endcount = 299999;
        endcount = 299999;
        nextcount = 499999;
        frame = 'assetss/Resizers/king.json';
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
        counted = "assetss/baronbatch.png";
        limit = 300000;
        endcount = 499999;
        endcount = 499999;
        nextcount = 1000000;
        frame = 'assetss/Resizers/sking.json';
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
        counted = "assetss/baronbatch.png";
        limit = 500000;
        endcount = 1000000;
        endcount = 1000000;
        nextcount = 12000000;
        frame = 'assetss/Resizers/ssking.json';
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

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    getdata();
    // getname();
    updateCounted();
    initializeNobelCount();
//nobelcount=(Provider.of<databasedata>(context,listen: false).Databases[0].count).toDouble();
   return FutureBuilder<User>(
        future: _futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('User not found'));
          } else {
            final user = snapshot.data!;
    
    
        return SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(nobelback), fit: BoxFit.cover)),
              child:
                  Consumer<databasedata>(builder: (context, databasedata, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
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
                                          color:
                                              const Color.fromARGB(255, 68, 68, 68))
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
                                      Navigator.of(context).push(MaterialPageRoute(
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
                            left: width / 20, right: width / 20, bottom: height / 40),
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
                                        user.name.toString(),
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
                                  if (nobelcount >= 500)...[
                                  SizedBox(
                                    width: width / 3,
                                    child: LottieBuilder.asset(
                                      frame,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  ],
                                
                                  if(nobelcount<500)...[
                                
                                    SizedBox(
                                      width: width/3,
                                      height: height/7,
                                    )
                                
                                  ]
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    top: height / 76, bottom: height / 60),
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      EdgeInsets.symmetric(horizontal: width / 30),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.money,
                                              color:
                                                  Color.fromARGB(255, 255, 255, 255),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                    
                    ]
                                ),
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
                                        lcolor: const Color.fromARGB(166, 17, 48, 18),
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
                                          "assetss/Resizers/Pawn Frame.png",
                                          "assetss/Resizers/Pawn Noble Name Plate.PNG",
                                        ],
                                        name: 'Pawn',
                                        fcolor: Color.fromARGB(166, 35, 97, 37),
                                        lcolor: const Color.fromARGB(166, 17, 48, 18),
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
                                          "assetss/Resizers/Rook Noble Badge.PNG",
                                          "assetss/Resizers/Rook Frame.png",
                                          "assetss/baron.png",
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
                                          "assetss/Resizers/Knight Noble Badge.PNG",
                                          "assetss/Resizers/Knight Frame.png",
                                          "assetss/Resizers/Knight Noble Badge Name.PNG",
                                          "assetss/Resizers/KnightFancyPlate.png",
                                          "assetss/Resizers/Knightcard.png"
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
                                          "assetss/Resizers/Bishop Noble Badge.PNG",
                                          "assetss/Resizers/Bishop Frame.png",
                                          "assetss/Resizers/Bishop Noble Badge Name.PNG",
                                          "assetss/Resizers/BishopFancyPlate.png",
                                                                              "assetss/Resizers/Bishopcard.png"
                      
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
                                          "assetss/Resizers/Queen-Noble-Badge.PNG",
                                          "assetss/Resizers/Queen Frame.png",
                                          "assetss/Resizers/Queen Noble Badge Name.PNG",
                                          "assetss/Resizers/QueenFancyPlate.png",
                                                                              "assetss/Resizers/Queencard.png"
                      
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
                                          "assetss/Resizers/Duke Noble Badge.PNG",
                                          "assetss/Resizers/Duke Frame.png",
                                          "assetss/Resizers/Duke Noble Badge Name.PNG",
                                          "assetss/Resizers/DukeFancyPlate.png",
                                                                              "assetss/Resizers/Dukecard.png"
                      
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
                                          "assetss/Resizers/King Noble Badge.PNG",
                                          "assetss/Resizers/King Frame.png",
                                          "assetss/Resizers/King Noble Badge Name.PNG",
                                          "assetss/Resizers/KingFancyPlate.png",
                                                                              "assetss/Resizers/Kingcard.png"
                      
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
                                          "assetss/Resizers/SKing Noble Badge.PNG",
                                          "assetss/Resizers/SKing Frame.png",
                                          "assetss/Resizers/SKing Noble Badge Name.PNG",
                                          "assetss/Resizers/SKingFancyPlate.png",
                                                                              "assetss/Resizers/SKingcard.png"
                      
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
                                          "assetss/Resizers/SSKing Noble Badge.PNG",
                                          "assetss/Resizers/SSKing Frame.png",
                                          "assetss/Resizers/SSKing Noble Badge Name.PNG",
                                          "assetss/Resizers/SSKingFancyPlate.png",
                                                                              "assetss/Resizers/SSKingcard.png"
                      
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
                );
              }),
            ),
          ),
        );
      }
        }
    );
  }
}
