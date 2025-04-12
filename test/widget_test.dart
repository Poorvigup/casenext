// Basic Flutter widget tests for CaseNext app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences for mocking

// Import your app's main file and screens
import 'package:case_management_app/main.dart';
import 'package:case_management_app/screens/login_screen.dart';
import 'package:case_management_app/screens/home_screen.dart';
import 'package:case_management_app/services/auth_service.dart'; // Import AuthService
import 'package:case_management_app/providers/case_provider.dart'; // Import CaseProvider

void main() {
  // --- Test Group for Initial Routing ---

  group('Initial Routing Tests', () {
    // Test case: When not logged in, LoginScreen should be shown
    testWidgets('Shows LoginScreen when not logged in', (WidgetTester tester) async {
      // Arrange: Set up SharedPreferences mock for the initial check in main()
      // (Though main() reads it before runApp, MyApp itself needs the isLoggedIn param)

      // Act: Build MyApp with isLoggedIn explicitly set to false.
      // We pass false directly because the initial check in main() is complex to mock here.
      // For this test, we focus on MyApp's behavior given the parameter.
      await tester.pumpWidget(const MyApp(isLoggedIn: false));
      await tester.pumpAndSettle(); // Ensure screen is built

      // Assert: Verify that LoginScreen is present and HomeScreen is not.
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      // Optionally, find specific widgets on the LoginScreen
      expect(find.text('CaseNext'), findsOneWidget); // App Name Title
      expect(find.text('Priority Driven Case Management'), findsOneWidget); // Tagline
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget); // Sign In button

      // Check if the Container with the background image exists
      // Finding by DecorationImage is harder, check for the container itself
      expect(find.byType(Container), findsWidgets); // Expect multiple containers, one holds the bg
    });

    // Test case: When logged in, HomeScreen should be shown
    testWidgets('Shows HomeScreen when logged in', (WidgetTester tester) async {
      // Arrange: (Similar to above, we focus on MyApp's parameter)

      // Act: Build MyApp with isLoggedIn explicitly set to true.
      await tester.pumpWidget(const MyApp(isLoggedIn: true));
      await tester.pumpAndSettle(); // Ensure screen is built

       // Assert: Verify that HomeScreen is present and LoginScreen is not.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Optionally, find specific widgets on the HomeScreen
      expect(find.text('Active Cases'), findsOneWidget); // AppBar Title
      // Find the specific FloatingActionButton.extended
      expect(find.widgetWithText(FloatingActionButton, 'New Case'), findsOneWidget);
    });
  });

  // --- Test Group for LoginScreen UI Elements ---
   group('LoginScreen UI Elements', () {
     testWidgets('Login screen displays required fields and button', (WidgetTester tester) async {

       // Build MyApp directing to LoginScreen
       await tester.pumpWidget(const MyApp(isLoggedIn: false));
       await tester.pumpAndSettle(); // Wait for potential animations/transitions

       // Find Username field (using labelText)
       expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);

       // Find Email field (using labelText)
       expect(find.widgetWithText(TextFormField, 'Email Address'), findsOneWidget);

       // Find Password field (using labelText)
       expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

       // Find Sign In button
       expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);

       // Check if the Container holding the background is present
       expect(find.byType(Container), findsWidgets);
     });
   });
}