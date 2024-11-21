import 'package:flutter/material.dart';
import 'models/database_data.dart';
import 'profilepage.dart';
import 'package:provider/provider.dart';

void main( )async{
 runApp(myapp());
}

class myapp extends StatelessWidget {
  const myapp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(create:(context) => databasedata(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Nobel_Project",
      home: profilepage(ID: 2,), 
      theme: ThemeData(brightness: Brightness.light),
    )
    );
  }
}