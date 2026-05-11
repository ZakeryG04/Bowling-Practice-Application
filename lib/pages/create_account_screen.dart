import 'package:flutter/material.dart';
import 'package:qu_bowling/services/profile_service.dart';
import 'package:qu_bowling/services/auth_service.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController(); // Used to compare passwords
  
  String _selectedRole = 'Athlete';
  String _selectedTeam = 'Mens Team';
  String _name = '';
  String _email = '';
  String _password = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _selectRole(String role) {
    setState(() => _selectedRole = role);
  }

  void _selectTeam(String team) {
    setState(() => _selectedTeam = team);
  }

  void _createAccount() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      try {
        final authService = AuthService();
        final response = await authService.signUp(
          email: _email,
          password: _password,
        );

        if (response.user != null) {
          final profileService = ProfileService();
          await profileService.createProfile(
            userId: response.user!.id,
            fullName: _name,
            role: _selectedRole,
          );

          if (!mounted) return;

          // 1. Sign out immediately after creation if email confirmation is ON
          // This prevents the app from trying to load a half-baked session.
          await authService.signOut(); 

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please sign in with your new credentials.'),
              backgroundColor: Colors.green,
            ),
          );

          // 2. Clear the navigation stack and go to Login
          // This ensures they don't just "pop" into a blank home screen
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        // ... your existing error handling
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 109, 51, 40), Color.fromARGB(255, 109, 51, 40)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildRoleSelector(),
                const SizedBox(height: 20),
                _buildTeamSelector(),
                const SizedBox(height: 28),
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 28, color: Colors.white),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quincy University', 
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('Bowling Program', 
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose your role', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildRoleButton('Athlete'),
            const SizedBox(width: 12),
            _buildRoleButton('Coach'),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleButton(String role) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () => _selectRole(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.white : Colors.white24),
          ),
          child: Center(
            child: Text(role, 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose your team', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTeamButton('Mens Team'),
            const SizedBox(width: 12),
            _buildTeamButton('Womens Team'),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamButton(String team) {
    final isSelected = _selectedTeam == team;
    return Expanded(
      child: InkWell(
        onTap: () => _selectTeam(team),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.white : Colors.white24),
          ),
          child: Center(
            child: Text(team, 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                validator: (val) => (val == null || val.isEmpty) ? 'Enter your name' : null,
                onSaved: (val) => _name = val ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || !val.contains('@quincy.edu')) return 'Use a quincy.edu email';
                  return null;
                },
                onSaved: (val) => _email = val ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController, // Use controller for easy comparison
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                obscureText: !_isPasswordVisible,
                validator: (val) => (val != null && val.length < 8) ? 'Minimum 8 characters' : null,
                onSaved: (val) => _password = val ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                ),
                obscureText: !_isConfirmPasswordVisible,
                validator: (val) => (val != _passwordController.text) ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createAccount,
                  child: const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}