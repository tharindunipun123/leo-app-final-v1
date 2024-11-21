import 'dart:convert';
import 'package:http/http.dart' as http;
import 'globals.dart';
import '../models/database.dart';



class DatabaseServices{

// static Future<databases> adddata(String title) async{

// Map data={

// "title":title,

// };

// var body=json.encode(data);
// var url =Uri.parse(baseURL + "/saveUser");

// http.Response response =await http.post(
  
//   url,
//   headers: header,
//   body: body
  
  
//   );

//   print(response.body);
//   Map<String, dynamic> responseMap=jsonDecode(response.body);
//   databases database =databases.fromMap(responseMap);

//   return database;


// }






// static Future<List<databases>> getdata()async{
 
//  var url=Uri.parse(baseURL+ "/getUser");
//  http.Response response = await http.get(
  
//   url,
//   headers:header
  
  
//   );
  

// print("chanuka${response.body}");
// List responseList=jsonDecode(response.body);
// List<databases> Databases=[];

// for(Map<String, dynamic> taskMap in responseList){

//   databases database=databases.fromMap(taskMap);
//   Databases.add(database);


// }
// return Databases;
// }


 static Future<databases> adddata(String datatitle, {
    required String title,
    int? year,
    int? month,
    int? day,
  }) async {
    // Use current date if year, month, and day are not provided
    final now = DateTime.now();
    final postYear = year ?? now.year;
    final postMonth = month ?? now.month;
    final postDay = day ?? now.day;

    Map<String, dynamic> data = {
      "title": title,
      "year": postYear,
      "month": postMonth,
      "day": postDay,
    };

    var body = json.encode(data);
    var url = Uri.parse(baseURL + "/totalGiftCount/2");

    http.Response response = await http.post(
      url,
      headers: header,
      body: body,
    );

    print(response.body);
    Map<String, dynamic> responseMap = jsonDecode(response.body);
    databases database = databases.fromMap(responseMap);

    return database;
  }

  static Future<List<databases>> getdata() async {
    var url = Uri.parse(baseURL + "/all");
    http.Response response = await http.get(
      url,
      headers: header,
    );

    print("chanuka${response.body}");
    List responseList = jsonDecode(response.body);
    List<databases> Databases = [];

    for (Map<String, dynamic> taskMap in responseList) {
      databases database = databases.fromMap(taskMap);
      Databases.add(database);
    }
    return Databases;
  }





}