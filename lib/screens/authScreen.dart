import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clubhouse/screens/homeScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/userModel.dart';
import './notInvitedScreen.dart';
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  bool isOtpScreen = false;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var verificationCode;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future phoneAuth()async{
    var _phoneNumber = phoneController.text.trim();
    setState(() {
      isLoading = true;
    });

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: _phoneNumber,
       verificationCompleted: (PhoneAuthCredential credential){
         _firebaseAuth.signInWithCredential(credential).then((userData)async{
           if(userData!=null){
             await _firestore.collection('users').doc(userData.user.uid).set({
               'name':'',
               'phone':userData.user.phoneNumber,
               'uid':userData.user.uid,
               'invitesLeft':5,
             });
            
             setState(() {
               isLoading = false;
             });
             // Navigate to HomeScreen in future
           }
         });

       }, 
       verificationFailed: (FirebaseAuthException error){
         print("Firebase Error : ${error.message}");
       },
        codeSent: (String verificationId,int resendToken){
          setState(() {
            isLoading = false;
            isOtpScreen = true;
            verificationCode = verificationId;
          });
        },
         codeAutoRetrievalTimeout: (String verificationId){
           setState(() {
             isLoading = false;
              verificationCode = verificationId;
           });
         },timeout: Duration(seconds: 120));

  }

  Future otpSignIn()async{
    setState(() {
      isLoading = true;
    });

    try{
      _firebaseAuth.signInWithCredential(PhoneAuthProvider.credential(verificationId: verificationCode, smsCode: otpController.text.trim())).then((userData)async{
        UserModel user;
        if(userData != null ){

          var userExist = await _firestore.collection('users').where('phone', isEqualTo: phoneController.text).get();

          if(userExist.docs.length > 0){
            print("USER ALREADY EXISTS");
            user = UserModel.fromMap(userExist.docs.first);
          }else{
            print("New User Created");
            user = UserModel(
            name: '',
            phone: userData.user.phoneNumber,
            invitesLeft: 5,
            uid: userData.user.uid,
          );
          await _firestore.collection('users').doc(userData.user.uid).set(UserModel().toMap(user));

          }

          var userInvited = await _firestore.collection('invites').where('invitee',isEqualTo: phoneController.text).get();
          if(userInvited.docs.length < 1){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>NotInvitedScreen()));
            return;
          }

           setState(() {
            isLoading = false;
          });
          print("Login Successful");

          Navigator.push(context, MaterialPageRoute(builder: (context)=>HomeScreen(user: user,)));


         
        }
      });
    }catch(e){
      print(e.toString());

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE7E4D3),
      body: Container(
          width: double.infinity,
        //  decoration: BoxDecoration(color: Colors.blue),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(top: 60),
                  height: 150,
                  child: Text("Club House",
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ),
                Expanded(
                    child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(60),
                        topRight: Radius.circular(60),
                      )),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 60,),
                       Image.asset('images/image1.png',height: 200,),
                       isOtpScreen ?  Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 20),
                          child: TextField(
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Enter Otp",
                                hintText: "Enter the otp you got"),
                          ),
                        ) :
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 20),
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "Enter Phone Number with country code",
                                hintText: "Enter your invited phone number"),
                          ),
                        ),
                         SizedBox(height: 30,),
                       isLoading? CircularProgressIndicator() : Container(
                          height: 50,
                          width: 250,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child:ElevatedButton(onPressed: (){
                            isOtpScreen ? otpSignIn():phoneAuth();
                          }, child: Text("Login",style: TextStyle(fontSize: 25,color: Colors.white),))

                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          )),
    );
  }
}
