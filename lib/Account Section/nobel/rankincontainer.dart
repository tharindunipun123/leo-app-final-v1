import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nobel_project/countdown.dart';

class rankingcontainer extends StatefulWidget {
  String ? name;
  String nobelcount;
  Widget leadingget;

  rankingcontainer(
      {required this.name,
      required this.nobelcount,
      required this.leadingget,
      super.key});

  @override
  State<rankingcontainer> createState() => _rankingcontainerState();
}

class _rankingcontainerState extends State<rankingcontainer> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      height: height / 9,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        color: Color.fromARGB(255, 255, 255, 255),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: width / 30, right: width / 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: width/1.7 ,
              child: Row(
                children: [
                  widget.leadingget,
                  Container(
                    width: width / 6,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                            image: NetworkImage("assetss/Resizers/User.jpg"),
                            fit: BoxFit.contain)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: height/25,left: width/40),
                    child: Container(
                      height: height / 9,
                      width: width / 4.2,
                      child: Text(
                        widget.name.toString(),
                        style: TextStyle(
                            fontSize: width / 23,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.money,
                  size: width / 25,
                  color: Colors.yellow,
                ),
                SizedBox(
                  width: width / 50,
                ),
                Text(
                  widget.nobelcount,
                  style: TextStyle(color: Colors.grey, fontSize: width / 25),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
