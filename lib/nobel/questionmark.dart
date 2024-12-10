import 'package:flutter/material.dart';

class question extends StatefulWidget {
  const question({super.key});

  @override
  State<question> createState() => _questionState();
}

class _questionState extends State<question> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;    
    return SafeArea(
      child: Scaffold(

        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(onPressed:() {
            Navigator.of(context).pop();
            
          }, icon:Icon(Icons.arrow_back_ios,size: width/20,color: Colors.black,)),
        title: Text("Nobility Upgrade",style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: width/20),),
        ),
        body: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(image: DecorationImage(image:AssetImage("assetss/Resizers/Noble Interface1 copy.jpg"),fit: BoxFit.contain)),
        ),
      
      ),
    );
  }
}