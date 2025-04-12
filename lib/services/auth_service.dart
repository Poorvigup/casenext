import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode; // For printing logs only in debug mode

class AuthService {
  // Keys for SharedPreferences
  static const String isLoggedInKey = 'isLoggedIn';
  static const String usernameKey = 'username';
  static const String emailKey = 'userEmail'; // Key to store email

  /// Simulates signing in a user.
  /// In a real app, replace the simulation with an API call to your backend.
  Future<bool> signIn(String username, String email, String password) async {
    if (kDebugMode) {
      print('Attempting login for: $username, Email: $email');
    }

    // --- VERY BASIC SIMULATION ---
    // Replace this with your actual backend authentication logic.
    // For now, it checks if fields are not empty and email has a basic format.
    if (username.isNotEmpty && _isValidEmail(email) && password.isNotEmpty) {
      // Simulate successful login
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(isLoggedInKey, true);
        await prefs.setString(usernameKey, username);
        await prefs.setString(emailKey, email); // Store email
        if (kDebugMode) {
          print('Login successful, storing user info.');
        }
        return true;
      } catch (e) {
         if (kDebugMode) {
          print('Error saving login state to SharedPreferences: $e');
        }
        return false; // Indicate failure if storage fails
      }
    } else {
      // Simulate failed login due to invalid input or failed backend auth
       if (kDebugMode) {
         print('Login failed: Invalid credentials or email format.');
       }
      return false;
    }
  }

  /// Simple email validation helper using regex.
  bool _isValidEmail(String email) {
    // This regex is common but might not cover all edge cases.
    // Consider using a package for more robust validation if needed.
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+$");
    return emailRegex.hasMatch(email.trim());
  }

  /// Signs the user out by clearing stored credentials.
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(isLoggedInKey);
      await prefs.remove(usernameKey);
      await prefs.remove(emailKey); // Remove email on sign out
      if (kDebugMode) {
        print('User signed out, clearing stored info.');
      }
    } catch (e) {
       if (kDebugMode) {
         print('Error clearing login state from SharedPreferences: $e');
       }
       // Decide if you need to handle this error further (e.g., inform the user)
    }
  }

  /// Checks if a user is currently logged in based on stored data.
  Future<bool> checkLoginStatus() async {
     final prefs = await SharedPreferences.getInstance();
     // Defaults to false if the key doesn't exist.
     return prefs.getBool(isLoggedInKey) ?? false;
  }

  /// Retrieves the stored username, returning null if not found.
  Future<String?> getUsername() async {
     final prefs = await SharedPreferences.getInstance();
     return prefs.getString(usernameKey);
  }

  /// Retrieves the stored email, returning null if not found.
   Future<String?> getEmail() async {
     final prefs = await SharedPreferences.getInstance();
     return prefs.getString(emailKey);
   }
}