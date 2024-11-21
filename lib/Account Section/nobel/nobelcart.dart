import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class nobelcart extends StatefulWidget {
  List img;
    List imgname;

  String name;
  Color fcolor;
  Color lcolor;
  String nobelbatch;
  String nobelpreve;

  nobelcart(
      {required this.img,
      required this.imgname,
      required this.name,
      required this.fcolor,
      required this.lcolor,
      required this.nobelbatch,
      required this.nobelpreve,
      super.key});

  @override
  State<nobelcart> createState() => _nobelcartState();
}

class _nobelcartState extends State<nobelcart> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Container(
      width: width / 1.05,
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(widget.nobelpreve), fit: BoxFit.fill),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: height / 120),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 5.2,
                      child: Divider(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        height: height / 30,
                        endIndent: 20,
                      ),
                    ),
                    Text(
                      "Display Privileges",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width / 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          BoxShadow(
                            blurRadius: 20,
                            blurStyle: BlurStyle.outer,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 5.2,
                      child: Divider(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        height: height / 30,
                        indent: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: height / 3.4,
            width: double.infinity,
            child: GridView.builder(
              itemCount: widget.img.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: height / 8,
              ),
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                      top: height / 65, left: width / 45, right: width / 45,bottom: height/80),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(widget.nobelbatch),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(widget.img[index]),
                                  fit: BoxFit.scaleDown,
                                  scale: 2,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            widget.imgname[index],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
