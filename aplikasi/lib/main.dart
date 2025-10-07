import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:animations/animations.dart';

import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';
import 'maps_page.dart';
import 'calendar_page.dart';
import 'profile_page.dart'; // ✅ gunakan file profile_page.dart kamu yang dinamis

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MomCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: "Roboto",
        scaffoldBackgroundColor: Colors.white,
      ),
      // ✅ Tambahan untuk localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("id", "ID"),
        Locale("en", "US"),
      ],

      initialRoute: "/",
      routes: {
        "/": (ctx) => const SplashScreen(),
        "/login": (ctx) => const LoginPage(),
        "/register": (ctx) => const RegisterPage(),
        "/main": (ctx) => const MainScreen(userId: 1), // 🔧 contoh default
      },
    );
  }
}

/// SplashScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    Timer(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacementNamed("/login");
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2BAE9C),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/baby.png", height: 140),
                const SizedBox(height: 16),
                const Text(
                  "MomCare",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ✅ Halaman utama dengan navigasi bawah
class MainScreen extends StatefulWidget {
  final int userId;
  const MainScreen({super.key, required this.userId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(key: const PageStorageKey("home"), userId: widget.userId),
      const MapsPage(key: PageStorageKey("maps")),
      CalendarPage(
        key: const PageStorageKey("calendar"),
        userId: widget.userId,
      ),
      ProfilePage(
        key: const PageStorageKey("profile"),
        userId: widget.userId,
      ), // ✅ gunakan ProfilePage dari file profile_page.dart
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation, secondaryAnimation) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) {
                final icons = [
                  Icons.home,
                  Icons.location_on,
                  Icons.calendar_month,
                  Icons.person,
                ];
                final labels = ["Home", "Maps", "Kalender", "Profile"];
                final isSelected = _currentIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons[index],
                          size: isSelected ? 28 : 24,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
