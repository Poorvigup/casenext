import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/case_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool(AuthService.isLoggedInKey) ?? false;
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    // Define a sophisticated color scheme
    const primaryColor = Color(0xFF2C3E50); // Dark Slate Blue/Grey
    const secondaryColor = Color(0xFF1ABC9C); // Teal/Turquoise Accent
    const backgroundColor = Color(0xFFF8F9FA); // Very Light Grey Background
    const cardBackgroundColor = Colors.white;
    const errorColor = Color(0xFFE74C3C); // Soft Red
    const textColor = Color(0xFF34495E); // Darker Grey Text
    const subtleTextColor = Color(0xFF7F8C8D); // Lighter Grey Text

    final baseTextTheme = GoogleFonts.latoTextTheme(Theme.of(context).textTheme); // Use Lato font

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<CaseProvider>(create: (_) => CaseProvider()..loadCases()),
      ],
      child: MaterialApp(
        title: 'CaseNext',
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: primaryColor,
          colorScheme: const ColorScheme.light(
            primary: primaryColor,
            secondary: secondaryColor,
            surface: cardBackgroundColor,
            background: backgroundColor,
            error: errorColor,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: textColor,
            onBackground: textColor,
            onError: Colors.white,
          ),
          scaffoldBackgroundColor: backgroundColor,

          // Use Google Fonts - Apply Lato
          textTheme: baseTextTheme.copyWith(
             displayLarge: baseTextTheme.displayLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold),
             displayMedium: baseTextTheme.displayMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold), // Used for Login Title (but overridden with white color there)
             displaySmall: baseTextTheme.displaySmall?.copyWith(color: textColor, fontWeight: FontWeight.bold),
             headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold), // Used for Login Title (but overridden with white color there)
             headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.bold), // Used for Dialog Titles
             titleLarge: baseTextTheme.titleLarge?.copyWith(color: textColor, fontWeight: FontWeight.bold, fontSize: 20), // App Bar Title Style
             titleMedium: baseTextTheme.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.w600, fontSize: 17), // Card Titles / Login Tagline (overridden color)
             titleSmall: baseTextTheme.titleSmall?.copyWith(color: textColor), // Card Priority %
             bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textColor, fontSize: 15), // Standard Body Text
             bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: subtleTextColor, fontSize: 14), // Subtitles, descriptions, dialog content
             bodySmall: baseTextTheme.bodySmall?.copyWith(color: subtleTextColor), // Card created date
             labelLarge: baseTextTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), // Button Text
          ).apply(
            bodyColor: textColor,
            displayColor: textColor,
          ),

          appBarTheme: AppBarTheme(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 2.0,
            titleTextStyle: baseTextTheme.titleLarge?.copyWith(color: Colors.white),
             iconTheme: const IconThemeData(color: Colors.white),
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.9), // Slightly transparent white fill
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: secondaryColor, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: errorColor, width: 1.0),
            ),
             focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: errorColor, width: 2.0),
            ),
            labelStyle: baseTextTheme.bodyMedium?.copyWith(color: subtleTextColor), // Label color
             hintStyle: baseTextTheme.bodyMedium?.copyWith(color: subtleTextColor.withOpacity(0.7)),
             prefixIconColor: subtleTextColor,
             errorStyle: TextStyle(color: errorColor.withOpacity(0.9), fontSize: 12.5, backgroundColor: Colors.black.withOpacity(0.1)) // Error text style for better visibility
          ),

          cardTheme: CardTheme(
            elevation: 3.0,
            color: cardBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: secondaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              textStyle: baseTextTheme.labelLarge,
              elevation: 2,
            ),
          ),

          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: secondaryColor,
              textStyle: baseTextTheme.labelLarge?.copyWith(color: secondaryColor, fontSize: 15, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),

          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: secondaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
          ),

          dialogTheme: DialogTheme(
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            elevation: 5,
             titleTextStyle: baseTextTheme.headlineSmall?.copyWith(color: textColor),
             contentTextStyle: baseTextTheme.bodyMedium?.copyWith(color: textColor),
          ),

          listTileTheme: ListTileThemeData(
              iconColor: primaryColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
              titleTextStyle: baseTextTheme.titleMedium,
              subtitleTextStyle: baseTextTheme.bodyMedium,
          ),

          iconTheme: const IconThemeData(
            color: primaryColor,
          ),

          snackBarTheme: SnackBarThemeData(
             backgroundColor: primaryColor.withOpacity(0.95), // Slightly transparent snackbar
             contentTextStyle: baseTextTheme.bodyMedium?.copyWith(color: Colors.white),
             behavior: SnackBarBehavior.floating, // <--- Behavior is floating
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
             elevation: 4,
             // --- This is the line you mentioned ---
             
             // ------------------------------------
          ),

          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: isLoggedIn ? HomeScreen.routeName : LoginScreen.routeName,
        routes: {
          LoginScreen.routeName: (context) => const LoginScreen(),
          HomeScreen.routeName: (context) => const HomeScreen(),
        },
      ),
    );
  }
}