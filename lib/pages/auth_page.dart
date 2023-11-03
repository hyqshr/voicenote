import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'profile_page.dart';


class AuthPage extends StatelessWidget {
  const AuthPage({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance
  .authStateChanges()
  .listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('User is signed in!');
    }
  });
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // If the connection to Firebase is still waiting, you can display a loading screen.
          return const CircularProgressIndicator();
        } else if (snapshot.hasData) {
          // If a user is signed in, navigate to the HomePage.
          print(snapshot.hasData);
          return ProfilePage();
        } else {
          // If no user is signed in, navigate to the LoginPage.
          return LoginPage();
        }
      },
    );
  }
}