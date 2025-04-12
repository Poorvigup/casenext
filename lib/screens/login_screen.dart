import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:case_management_app/services/auth_service.dart'; // Assuming path is correct
import 'package:case_management_app/screens/home_screen.dart'; // Assuming path is correct

class LoginScreen extends StatefulWidget {
  static const routeName = '/login'; // Route name for navigation
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Global key for the form state
  final _formKey = GlobalKey<FormState>();
  // Text editing controllers for input fields
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  // State variables for loading indicator and error messages
  bool _isLoading = false;
  String? _errorMessage;

  // Email Validation Helper
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    // Basic regex for email validation (adjust as needed)
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+$");
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null; // Return null if valid
  }

  // Dispose controllers when the widget is removed from the tree
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to handle the login submission
  Future<void> _submitLogin() async {
    // Hide keyboard first
    FocusScope.of(context).unfocus();

    // Validate the form using the GlobalKey
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Stop if form is invalid
    }

    // Show loading indicator and clear previous errors
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Access AuthService using Provider (read doesn't listen for changes)
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Attempt sign in using the AuthService
      final success = await authService.signIn(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text, // Passwords usually aren't trimmed
      );

      // IMPORTANT: Check if the widget is still mounted before updating state/navigating
      if (!mounted) return;

      if (success) {
        // Navigate to HomeScreen on successful login, replacing LoginScreen
        Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
      } else {
        // Show an error message if login fails
        setState(() {
          _errorMessage = 'Login failed. Check credentials or email format.';
        });
      }
    } catch (e) {
      // Handle any unexpected errors during the sign-in process
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred. Please try again.';
          print("Login Error: $e"); // Log the actual error in debug mode
        });
      }
    } finally {
      // Ensure the loading indicator is hidden, even if errors occurred
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Build the UI for the LoginScreen
  @override
  Widget build(BuildContext context) {
    // Get theme data for consistent styling
    final theme = Theme.of(context);
    // Get screen height for relative sizing (optional)
    // final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // Allow the screen to resize when the keyboard appears
      resizeToAvoidBottomInset: true,
      body: Container( // Main container for the background image
        height: double.infinity, // Take full screen height
        width: double.infinity,  // Take full screen width
        decoration: BoxDecoration(
          image: DecorationImage(
            // Specify the background image asset
            image: const AssetImage("assets/images/law.jpg"),
            // Make the image cover the entire container
            fit: BoxFit.cover,
            // Apply a dimming overlay for text readability
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.55), // Adjust opacity for darkness
              BlendMode.darken, // Blending mode
            ),
            // Optional: Handle errors if the image fails to load
            onError: (exception, stackTrace) {
                 print("LoginScreen: Error loading background image: $exception");
             },
          ),
        ),
        child: Center( // Center the content vertically and horizontally
          child: SingleChildScrollView( // Enable scrolling for smaller screens
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0), // Padding around the content
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center column content vertically
              children: <Widget>[
                const SizedBox(height: 40), // Add some space at the top

                // App Name Display
                Text(
                  'CaseNext',
                  style: theme.textTheme.headlineMedium?.copyWith( // Use theme style as base
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text for contrast
                    fontSize: 38, // *** INCREASED FONT SIZE ***
                    shadows: [ // Add subtle shadow for readability
                      const Shadow(blurRadius: 2.0, color: Colors.black54, offset: Offset(1, 1))
                    ]
                  ),
                  textAlign: TextAlign.center,
                ),

                // App Tagline Display
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 40.0), // Adjust vertical padding
                  child: Text(
                    'Priority Driven Case Management',
                    style: theme.textTheme.titleMedium?.copyWith( // Use theme style as base
                      color: theme.colorScheme.secondary.withOpacity(0.95), // Use accent color
                      fontWeight: FontWeight.w500,
                      fontSize: 19, // *** INCREASED FONT SIZE ***
                       shadows: [ // Add subtle shadow
                        const Shadow(blurRadius: 1.0, color: Colors.black45, offset: Offset(1, 1))
                       ]
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Login Form Widget
                Form(
                  key: _formKey, // Assign the global key
                  child: Column(
                    children: [
                      // Username Text Field
                      TextFormField(
                        controller: _usernameController,
                        // Ensure input text is visible on light background of field
                        style: const TextStyle(color: Colors.black87),
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline),
                          // Input field styling comes from inputDecorationTheme in main.dart
                        ),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next, // Move focus to next field
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'Please enter your username' : null, // Basic validation
                      ),
                      const SizedBox(height: 20), // Spacing between fields

                      // Email Text Field
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next, // Move focus to password field
                        validator: _validateEmail, // Use custom email validator
                      ),
                      const SizedBox(height: 20),

                      // Password Text Field
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.black87),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                          // Consider adding a suffix icon to toggle password visibility
                        ),
                        obscureText: true, // Hide password input
                        textInputAction: TextInputAction.done, // Indicate final field
                        // Submit form when 'done' is pressed on the keyboard
                        onFieldSubmitted: (_) => _isLoading ? null : _submitLogin(),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter your password';
                          // Add basic password length validation
                          if (value.length < 6) return 'Password must be at least 6 characters';
                          return null; // Return null if valid
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25), // Spacing before error message/button

                // Error Message Display Area (Animated)
                AnimatedOpacity(
                  // Control visibility based on _errorMessage
                  opacity: _errorMessage != null ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300), // Fade animation duration
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Text(
                      _errorMessage ?? '', // Display the error message or an empty string
                      style: TextStyle(
                        color: Colors.red[100], // Lighter red for better visibility on dark background
                        fontWeight: FontWeight.w500,
                        shadows: const [Shadow(blurRadius: 1.0, color: Colors.black54)] // Add shadow
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                 const SizedBox(height: 10), // Spacing

                // Conditional Widget: Loading Indicator or Login Button
                _isLoading
                    // Show loading indicator while processing login
                    ? CircularProgressIndicator(
                        color: theme.colorScheme.secondary, // Use accent color
                        backgroundColor: Colors.white.withOpacity(0.3), // Optional background for indicator
                      )
                    // Show login button when not loading
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.login, size: 40),
                        label: const Text('Sign In'),
                        onPressed: _submitLogin, // Call submit function on press
                        // Button styling comes from elevatedButtonTheme in main.dart
                      ),
                const SizedBox(height: 90), // Add some space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}