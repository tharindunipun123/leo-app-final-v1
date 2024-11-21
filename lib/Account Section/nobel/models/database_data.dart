import 'package:flutter/foundation.dart';
import '../Service/database_services.dart';
import 'database.dart';


class databasedata extends ChangeNotifier{

List<databases> Databases =[];

void adddata(String datatitle) async{

databases database =await DatabaseServices.adddata(datatitle, title: '');
Databases.add(database);
notifyListeners();


}



}