import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'package:qu_bowling/services/auth_service.dart';
import 'package:qu_bowling/services/profile_service.dart';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({super.key, required this.role});

  final String role;

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isPasswordVisible = false;

  void _signIn() async {
  if (_formKey.currentState?.validate() ?? false) {
    _formKey.currentState?.save();

    try {
      final authService = AuthService();
      final response = await authService.signIn(
        email: _email,
        password: _password,
      );

      if (response.user != null) {
        final profileService = ProfileService();
        final existingProfile = await profileService.getCurrentUserProfile();

        // 1. If profile exists, check if the role matches the tab they used
        if (existingProfile != null) {
          // Compare the DB role to the Tab role (widget.role)
// Safe comparison using null-safety operators
String dbRole = existingProfile.role?.toLowerCase() ?? 'athlete';
String targetRole = widget.role.toLowerCase();

if (dbRole != targetRole) {
  await authService.signOut();
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Access Denied: This is an ${existingProfile.role ?? "Athlete"} account.'),
        backgroundColor: Colors.red,
      ),
    );
  }
  return; 
}
        } else {
          // 2. Only create a profile if one truly doesn't exist 
          // (First time login / New user)
          await profileService.createProfile(
            userId: response.user!.id,
            role: widget.role,
          );
        }

        // 3. Success: Roles match or a new profile was created correctly
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Signed in as ${widget.role}'),
              duration: const Duration(seconds: 2),
            ),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In as ${widget.role}'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 109, 51, 40), // Main brown
              Color.fromARGB(255, 109, 51, 40), // Medium brown
              Color.fromARGB(255, 109, 51, 40), // Light brown
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),
                // Quincy University Logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.groups,
                          size: 32,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quincy University',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Bowling',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: Colors.white.withOpacity(0.9),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const Key('emailField'),
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'name@quincy.edu',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your email';
                              }
                              final email = value.trim();
                              if (!email.contains('@') || !email.toLowerCase().endsWith('quincy.edu')) {
                                return 'Enter a valid quincy.edu email';
                              }
                              return null;
                            },
                            onSaved: (value) => _email = value ?? '',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('passwordField'),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter your password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                            onSaved: (value) => _password = value ?? '',
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Sign In'),
                          ),
                        ],
                      ),
                    ),
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