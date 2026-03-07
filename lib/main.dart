import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/root_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qbagkblowxkrjptwbjia.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFiYWdrYmxvd3hrcmpwdHdiamlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3OTY0ODEsImV4cCI6MjA3NDM3MjQ4MX0.tuZLYuBqe7AnOP4d7iTI8PQW7lOZLQ5bhkNkL8Abzi8',
  );

  Stripe.publishableKey = 'pk_test_51T67Q5Qp6RK9fuHDtCJ1IgBdUM7KL46fR4HWtss7zs1ebeSzCTKTMJHVndSAAggxunnUwJNPH3OpW8RxzhJp3Kl100PyNwINjB';
  await Stripe.instance.applySettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0077B6); // ✅ Ocean Blue (Travel standard)
    const secondary = Color(0xFF00B4D8); // ✅ Sky Blue accent
    const bg = Color(0xFFF8FAFC); // ✅ clean background

    return MaterialApp(
      title: 'TraveLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        // ✅ Standard Material 3 ColorScheme (IMPORTANT)
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          surface: Colors.white,
          background: bg,
        ),

        scaffoldBackgroundColor: bg,

        // ✅ AppBar standard style (clean)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),

        // ✅ Buttons standard style
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),

        // ✅ Input fields standard
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
        ),

        // ✅ Dividers standard
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE5E7EB),
          thickness: 1,
        ),
      ),
      home: const RootScreen(), // Changed from WelcomeScreen
    );
  }
}
