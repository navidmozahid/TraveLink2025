import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/root_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qbagkblowxkrjptwbjia.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFiYWdrYmxvd3hrcmpwdHdiamlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3OTY0ODEsImV4cCI6MjA3NDM3MjQ4MX0.tuZLYuBqe7AnOP4d7iTI8PQW7lOZLQ5bhkNkL8Abzi8',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TraveLink', // Changed from XplorerHub
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF023e8a),
        useMaterial3: true,
      ),
      home: const RootScreen(), // Changed from WelcomeScreen
    );
  }
}