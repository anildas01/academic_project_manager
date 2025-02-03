import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'faculty_home_page.dart';
import 'student_home_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String selectedRole = 'Student';
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Student Login Section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 120, color: Colors.purple),
                  const SizedBox(height: 24),
                  const Text(
                    'Student Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Not a member yet? Sign up!',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  _buildLoginForm('Student'),
                ],
              ),
            ),
          ),
          // Vertical Divider
          Container(
            width: 1,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(vertical: 32),
          ),
          // Faculty Login Section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_2, size: 120, color: Colors.green),
                  const SizedBox(height: 24),
                  const Text(
                    'Teacher Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Not a member yet? Sign up!',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  _buildLoginForm('Faculty'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(String role) {
    bool isSelected = selectedRole == role;

    return Form(
      key: role == selectedRole ? _formKey : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email/Phone Field
          TextField(
            controller: isSelected ? _emailController : null,
            enabled: isSelected,
            decoration: InputDecoration(
              hintText: 'Username or Email',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue[300]!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Password Field
          TextField(
            controller: isSelected ? _passwordController : null,
            enabled: isSelected,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue[300]!),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Remember me & Forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: false,
                    onChanged: isSelected ? (value) {} : null,
                  ),
                  Text(
                    'Remember me',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              TextButton(
                onPressed: isSelected ? () {} : null,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Login Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSelected
                  ? () {
                      selectedRole = role;
                      handleLogin();
                    }
                  : () {
                      setState(() => selectedRole = role);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading && isSelected
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(isSelected ? 'Login' : 'Select ${role} Login'),
            ),
          ),
          const SizedBox(height: 24),
          // Social Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialButton(Icons.facebook, Colors.blue),
              const SizedBox(width: 16),
              _socialButton(Icons.g_mobiledata, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialButton(IconData icon, Color color) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }

  Future<void> handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final contact = _emailController.text.trim();
        final password = _passwordController.text;

        final userData = await _firebaseService.verifyLogin(
          contact,
          password,
          selectedRole,
        );

        setState(() {
          isLoading = false;
        });

        if (userData != null) {
          if (selectedRole.toLowerCase() == 'student') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StudentHomePage(studentData: userData),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FacultyHomePage(facultyData: userData),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid credentials'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred during login'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
