import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/customer_auth_service.dart';
import '../services/firebase_user_service.dart';
import 'email_otp_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Google Logo Icon (official multi-colour "G")
// ─────────────────────────────────────────────────────────────────────────────

/// Styled Multi-color Google "G" Icon
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22;
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22;
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22;
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22;

    canvas.drawArc(rect.deflate(size.width * 0.11), 3.9, 1.6, false, redPaint);
    canvas.drawArc(rect.deflate(size.width * 0.11), 2.3, 1.6, false, yellowPaint);
    canvas.drawArc(rect.deflate(size.width * 0.11), 0.7, 1.6, false, greenPaint);
    canvas.drawArc(rect.deflate(size.width * 0.11), 5.5, 1.4, false, bluePaint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(
      center.dx,
      center.dy - (size.height * 0.11),
      radius,
      size.height * 0.22,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
//  "Continue with Google" Button
// ─────────────────────────────────────────────────────────────────────────────

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = 'Continue with Google',
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        side: BorderSide(color: Colors.grey.shade300, width: 1.2),
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4285F4)),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleLogoIcon(size: 20),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3C4043),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Google Authentication Flow Manager
// ─────────────────────────────────────────────────────────────────────────────

/// Orchestrates the REAL Google Sign-In flow:
///  1. Opens the official Google Account Chooser (via google_sign_in SDK)
///  2. Gets the idToken and verifies it with the Laravel backend
///  3. For brand-new customers: collects delivery credentials + OTP
///  4. Syncs the profile to Firebase Firestore and sets the active session
class GoogleAuthFlow {
  static Future<UserModel?> startGoogleSignIn(BuildContext context) async {
    try {
      // ── Step 1 & 2: Real Google Sign-In (account chooser + backend verify) ─
      final result = await CustomerAuthService.signInWithGoogle();

      final String email  = result['email'] ?? '';
      final String name   = result['name']  ?? '';
      final String avatar = result['avatar'] ?? '';
      final int    userId = result['id'] ?? 0;

      if (email.isEmpty) {
        if (context.mounted) {
          _showError(context, 'Google sign-in returned no email address.');
        }
        return null;
      }

      // ── Step 3: Check if this customer already has a full profile ──────────
      final existingUser = await FirebaseUserService.findUserProfile(email);
      if (existingUser != null &&
          existingUser.phoneNumber.isNotEmpty &&
          existingUser.address.isNotEmpty) {
        // Returning customer — just restore session
        FirebaseUserService.setCurrentUser(existingUser);
        if (context.mounted) {
          _showSuccess(context, 'Welcome back, ${existingUser.firstName}! 🎉');
        }
        return existingUser;
      }

      if (!context.mounted) return null;

      // ── Step 4: New customer — collect delivery credentials ───────────────
      final credentials = await showDialog<UserModel>(
        context: context,
        barrierDismissible: false,
        barrierColor: const Color(0xCC000000),
        builder: (ctx) => _GoogleAskCredentialsDialog(
          initialEmail: email,
          initialName: name,
          avatarUrl: avatar,
        ),
      );

      if (credentials == null) return null;

      // ── Step 5: OTP Email Verification ───────────────────────────────────
      if (!context.mounted) return null;
      final isOtpVerified = await EmailOtpDialog.verify(
        context,
        email: credentials.emailAddress,
      );

      if (!isOtpVerified) {
        if (context.mounted) {
          _showError(
            context,
            'Email verification not completed. Please try again.',
          );
        }
        return null;
      }

      // ── Step 6: Persist to Firebase + set session ─────────────────────────
      await FirebaseUserService.saveUserProfileToFirebase(credentials);
      FirebaseUserService.setCurrentUser(credentials);

      if (context.mounted) {
        _showSuccess(context, 'Account linked! Welcome, ${credentials.firstName} 🎉');
      }

      return credentials;
    } on Exception catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg == 'sign_in_cancelled') return null; // User cancelled — silent
      if (context.mounted) _showError(context, msg);
      return null;
    } catch (e) {
      if (context.mounted) _showError(context, 'Unexpected error: $e');
      return null;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB3261E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  New-Customer Credentials Dialog (dark Google-style)
// ─────────────────────────────────────────────────────────────────────────────

class _GoogleAskCredentialsDialog extends StatefulWidget {
  final String initialEmail;
  final String initialName;
  final String avatarUrl;

  const _GoogleAskCredentialsDialog({
    required this.initialEmail,
    required this.initialName,
    this.avatarUrl = '',
  });

  @override
  State<_GoogleAskCredentialsDialog> createState() =>
      _GoogleAskCredentialsDialogState();
}

class _GoogleAskCredentialsDialogState
    extends State<_GoogleAskCredentialsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _secondNameCtrl;
  final _middleNameCtrl = TextEditingController();
  final _birthdayCtrl   = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _phoneCtrl      = TextEditingController();

  @override
  void initState() {
    super.initState();
    final parts = widget.initialName.trim().split(' ');
    _firstNameCtrl  = TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    _secondNameCtrl = TextEditingController(
      text: parts.length > 1 ? parts.sublist(1).join(' ') : '',
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _secondNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _birthdayCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _birthdayCtrl.text =
          '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final user = UserModel(
      firstName:    _firstNameCtrl.text.trim(),
      secondName:   _secondNameCtrl.text.trim(),
      middleName:   _middleNameCtrl.text.trim(),
      birthday:     _birthdayCtrl.text.trim(),
      address:      _addressCtrl.text.trim(),
      phoneNumber:  _phoneCtrl.text.trim(),
      emailAddress: widget.initialEmail.trim(),
      isVerified:   true,
    );
    Navigator.of(context).pop(user);
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFE8411E);

    return Dialog(
      backgroundColor: const Color(0xFF1E1F20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF444746)),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Row(
                  children: [
                    const GoogleLogoIcon(size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          color: Color(0xFFE3E3E3),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF8E918F)),
                      onPressed: () => Navigator.of(context).pop(null),
                    ),
                  ],
                ),

                // ── Google account badge ────────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(top: 10, bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF041E49),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0842A0)),
                  ),
                  child: Row(
                    children: [
                      // Show avatar initial or photo
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF4285F4),
                        backgroundImage: widget.avatarUrl.isNotEmpty
                            ? NetworkImage(widget.avatarUrl)
                            : null,
                        child: widget.avatarUrl.isEmpty
                            ? Text(
                                widget.initialEmail.isNotEmpty
                                    ? widget.initialEmail[0].toUpperCase()
                                    : 'G',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.initialEmail,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFA8C7FA),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Text(
                  'Please provide your delivery details to continue:',
                  style: TextStyle(fontSize: 13, color: Color(0xFFC4C7C5)),
                ),
                const SizedBox(height: 18),

                // ── Name fields ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _firstNameCtrl,
                        label: 'First Name *',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _secondNameCtrl,
                        label: 'Last Name *',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Middle name + Birthday ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _middleNameCtrl,
                        label: 'Middle Name (Optional)',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _birthdayCtrl,
                        label: 'Birthday *',
                        readOnly: true,
                        onTap: _pickBirthday,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today,
                              size: 16, color: Color(0xFFA8C7FA)),
                          onPressed: _pickBirthday,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Address ────────────────────────────────────────────────
                _buildField(
                  controller: _addressCtrl,
                  label: 'Complete Delivery Address *',
                  hint: 'House/Unit, Street, Barangay, City',
                  prefixIcon: const Icon(Icons.home_outlined,
                      size: 18, color: Color(0xFF8E918F)),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Delivery address is required'
                      : null,
                ),
                const SizedBox(height: 14),

                // ── Phone (strictly 11 digits) ─────────────────────────────
                _buildField(
                  controller: _phoneCtrl,
                  label: 'Contact Number (11 Digits) *',
                  hint: '09XXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_android,
                      size: 18, color: Color(0xFF8E918F)),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Contact number is required';
                    }
                    if (!RegExp(r'^09[0-9]{9}$').hasMatch(v.trim())) {
                      return 'Must be exactly 11 digits starting with 09';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),

                // ── Submit button ──────────────────────────────────────────
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Verify Email & Finish (OTP)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9AA0A6), fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF5F6368), fontSize: 12),
        isDense: true,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF444746)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFFA8C7FA), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFF2B8B5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFFF2B8B5), width: 1.5),
        ),
      ),
    );
  }
}
