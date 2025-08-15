import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:activo/pages/login_page.dart';
import './pages/homepage.dart';
import './pages/choose_exercise.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCM1yJ1zoOtpEOdhS4eAbwdT3X2zJj5qO4",
      authDomain: "habitaura-7b193.firebaseapp.com",
      projectId: "habitaura-7b193",
      storageBucket: "habitaura-7b193.firebasestorage.app",
      messagingSenderId: "638285838015",
      appId: "1:638285838015:web:3897a2f44a27dc275bf80a",
      measurementId: "G-C3GNNYKNJ7",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Activo',
      theme: ThemeData.dark(),
      routes: {'/choose_exercise': (context) => const ChooseExercisePage()},
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return MyHomePage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
