import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_user_service.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _firstNameCtrl = TextEditingController();
  final _secondNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _secondNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _birthdayCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_firstNameCtrl.text.trim().isEmpty ||
        _secondNameCtrl.text.trim().isEmpty ||
        _addressCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final newUser = UserModel(
      firstName: _firstNameCtrl.text.trim(),
      secondName: _secondNameCtrl.text.trim(),
      middleName: _middleNameCtrl.text.trim(),
      birthday: _birthdayCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      emailAddress: _emailCtrl.text.trim(),
      isVerified: true,
    );

    // Save to Firebase Cloud Firestore
    await FirebaseUserService.saveUserProfileToFirebase(newUser);
    FirebaseUserService.setCurrentUser(newUser);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account Created Successfully! Please log in to continue. 🎉'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFE8411E);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sign Up as Verified User',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fill in your details once for instant auto-fill during checkout',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('First Name *', _firstNameCtrl, Icons.person)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Second (Last) Name *', _secondNameCtrl, Icons.person_outline)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Middle Name', _middleNameCtrl, Icons.badge)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Birthday (YYYY-MM-DD)', _birthdayCtrl, Icons.cake)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('Address *', _addressCtrl, Icons.home),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Phone Number *', _phoneCtrl, Icons.phone)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField('Email Address *', _emailCtrl, Icons.email)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('Password *', _passwordCtrl, Icons.lock, obscureText: true),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSignup,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: brandColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Create Verified Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?", style: TextStyle(fontSize: 13)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: Icon(icon, size: 16, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE8411E)),
            ),
          ),
        ),
      ],
    );
  }
}
