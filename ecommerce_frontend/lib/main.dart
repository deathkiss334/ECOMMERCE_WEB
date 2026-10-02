import 'package:flutter/material.dart';
import 'admin/admin_layout.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'landing_page.dart';
import 'customer/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color brandColor = Color(0xFFF36F21);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DasmaBITES - Your Favorite Bites, Just a Click Away!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandColor,
          primary: brandColor,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/shop': (context) => const HomeScreen(),
        '/admin': (context) => const AdminLayout(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
      },
    );
  }
}
