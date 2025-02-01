import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../utils/password_validator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseService _firebaseService = FirebaseService();
  String selectedRole = 'Student';
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool isContactFound = false;
  bool showOtpField = false;
  bool showPasswordFields = false;
  bool isLoading = false;

  double _passwordStrength = 0;

  Future<void> checkDatabase() async {
    if (_formKey.currentState!.validate()) {
      final contact = _emailPhoneController.text.trim();

      // Show loading indicator
      setState(() {
        isLoading = true;
      });

      try {
        final exists =
            await _firebaseService.verifyContact(contact, selectedRole);

        setState(() {
          isLoading = false;
          isContactFound = exists;
          showOtpField = exists;
        });

        if (exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your contact'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Contact not found in $selectedRole database'),
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
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      final contact = _emailPhoneController.text.trim();
      final otp = _otpController.text.trim();

      setState(() {
        isLoading = true;
      });

      try {
        final isValid = await _firebaseService.verifyOTP(contact, otp);

        setState(() {
          isLoading = false;
        });

        if (isValid) {
          setState(() {
            showOtpField = false;
            showPasswordFields = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP verified successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid OTP or OTP expired'),
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
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> completeRegistration() async {
    if (_formKey.currentState!.validate()) {
      final contact = _emailPhoneController.text.trim();
      final password = _passwordController.text;

      setState(() {
        isLoading = true;
      });

      try {
        bool success;
        if (selectedRole.toLowerCase() == 'student') {
          success = await _firebaseService.storeStudentCredentials(
            contact,
            password,
          );
        } else {
          success = await _firebaseService.storeFacultyCredentials(
            contact,
            password,
          );
        }

        setState(() {
          isLoading = false;
        });

        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration completed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to complete registration'),
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
            content: Text('An error occurred during registration'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPasswordStrengthIndicator() {
    Color indicatorColor;
    String strengthText;

    if (_passwordStrength <= 0.3) {
      indicatorColor = Colors.red;
      strengthText = 'Weak';
    } else if (_passwordStrength <= 0.7) {
      indicatorColor = Colors.orange;
      strengthText = 'Medium';
    } else {
      indicatorColor = Colors.green;
      strengthText = 'Strong';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: _passwordStrength,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
        const SizedBox(height: 4),
        Text(
          'Password Strength: $strengthText',
          style: TextStyle(
            color: indicatorColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Password must contain:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const Text(
          '• At least 8 characters\n'
          '• At least one uppercase letter\n'
          '• At least one lowercase letter\n'
          '• At least one number\n'
          '• At least one special character',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!showPasswordFields) ...[
                      // Initial Registration Phase
                      // Role Selection
                      DropdownButton<String>(
                        value: selectedRole,
                        items: ['Student', 'Faculty']
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ))
                            .toList(),
                        onChanged: !isContactFound
                            ? (value) {
                                setState(() {
                                  selectedRole = value!;
                                });
                              }
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Email/Phone Field
                      TextFormField(
                        controller: _emailPhoneController,
                        enabled: !isContactFound,
                        decoration: const InputDecoration(
                          labelText: 'Email or Phone Number',
                          border: OutlineInputBorder(),
                          hintText: 'Enter registered email or phone',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email or phone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Verify Contact Button
                      if (!isContactFound)
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              checkDatabase();
                            }
                          },
                          child: const Text('Verify Contact'),
                        ),

                      // OTP Field
                      if (showOtpField) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _otpController,
                          decoration: const InputDecoration(
                            labelText: 'Enter OTP',
                            border: OutlineInputBorder(),
                            hintText: 'Enter the OTP sent to your contact',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              verifyOtp();
                            }
                          },
                          child: const Text('Verify OTP'),
                        ),
                      ],
                    ] else ...[
                      // Password Setup Phase
                      const Text(
                        'Set Your Password',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        onChanged: (value) {
                          setState(() {
                            _passwordStrength =
                                PasswordValidator.calculateStrength(value);
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          return PasswordValidator.validatePassword(value);
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildPasswordStrengthIndicator(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            completeRegistration();
                          }
                        },
                        child: const Text('Complete Registration'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
