import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://qbagkblowxkrjptwbjia.supabase.co', // your project URL
    anonKey: 'YOUR_ANON_KEY_HERE', // replace with your anon public key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XplorerHub',
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}
