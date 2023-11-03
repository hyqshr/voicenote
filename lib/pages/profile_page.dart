import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            if (user != null)
              Text(
                'User Email: ${user.email}',
                style: const TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Implement sign out logic here
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (e) {
                  print('Error signing out: $e');
                }
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
