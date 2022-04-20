import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clubhouse/screens/authScreen.dart';
import 'package:clubhouse/screens/homeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import './models/userModel.dart';
import './screens/notInvitedScreen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}





class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Club House',
      theme: ThemeData(
      
        primarySwatch: Colors.blue,
      
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthenticateUser(),
    );
  }
}


class AuthenticateUser extends StatelessWidget {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;


  Future checkCurrentUser()async{
    if(_firebaseAuth.currentUser !=null){
     var userInvited =  await FirebaseFirestore.instance.collection('invites').where('invitee',isEqualTo: _firebaseAuth.currentUser.phoneNumber).get();
          if(userInvited.docs.length < 1){
            return NotInvitedScreen();
          }
      var userExist = await FirebaseFirestore.instance.collection('users').where('uid',isEqualTo:_firebaseAuth.currentUser.uid).get();
      UserModel user = UserModel.fromMap(userExist.docs.first);
      return HomeScreen(user: user);
    }else{
      return AuthScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkCurrentUser(),
      builder: (context,snapshot){
        if(snapshot.connectionState==ConnectionState.waiting){
          return Container(
            
            color:Color(0xFFE7E4D3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('images/image1.png',height: 250,),
                SizedBox(height: 50,),
                CircularProgressIndicator(
                  backgroundColor: Colors.white,
                )
              ],
            )
          );
        }else{
          return snapshot.data;
        }
        
      },
      
    );
  }
}