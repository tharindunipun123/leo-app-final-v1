import 'package:flutter/material.dart';
import 'package:rankingpage/rankingpage.dart';

class question extends StatefulWidget {
  const question({super.key});

  @override
  State<question> createState() => _questionState();
}

class _questionState extends State<question> {
  @override
  Widget build(BuildContext context) {
       final width = MediaQuery.of(context).size.width;
   final height =MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
         appBar:AppBar(
          title:Padding(
            padding:  EdgeInsets.only(top: height/60),
            child: Text("My Levels",style: TextStyle(color: Colors.black,fontSize: width/30),textAlign: TextAlign.left,),
          )
,
          backgroundColor: Colors.white,
        leading:    Padding(
      padding:  EdgeInsets.only(top: height/60,left: width/30),
      child: GestureDetector(
        onTap: () {
         
         Navigator.of(context).pop();
         
        },
        child: Icon(
         Icons.arrow_back_ios,
         size:width / 25,
         color: Colors.black,
                          ),
      ),
    ),

         ) ,
         body: SingleChildScrollView(
           child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
             children: [
               Container(
                height: height*2 +200,
                width: width,
                decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage("assetss/images/photo_2024-07-07_11-33-02.jpg"),fit: BoxFit.cover)
                ),
               ),
             ],
           ),
         ),
      
      
      ),
    );
  }
}