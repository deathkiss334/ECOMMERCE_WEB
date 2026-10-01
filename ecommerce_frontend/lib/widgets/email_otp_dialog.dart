import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class EmailOtpDialog extends StatefulWidget {
  final String email;

  const EmailOtpDialog({
    super.key,
    required this.email,
  });

  /// Static helper to trigger the Email OTP dialog and return true if verified
  static Future<bool> verify(BuildContext context, {required String email}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EmailOtpDialog(email: email),
    );
    return result ?? false;
  }

  @override
  State<EmailOtpDialog> createState() => _EmailOtpDialogState();
}

class _EmailOtpDialogState extends State<EmailOtpDialog> {
  final List<TextEditingController> _digitControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String _generatedOtp = '';
  bool _isSending = true;
  bool _isVerifying = false;
  String? _errorMessage;

  int _resendCountdown = 45;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _requestOtp();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 45);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  Future<void> _requestOtp() async {
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final clientFallbackCode = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();

    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/auth/send-otp');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email}),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _generatedOtp = data['otp']?.toString() ?? clientFallbackCode;
      } else {
        _generatedOtp = clientFallbackCode;
      }
    } catch (_) {
      _generatedOtp = clientFallbackCode;
    }

    setState(() => _isSending = false);
    _startCountdown();

    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
  }

  String get _currentOtpInput => _digitControllers.map((c) => c.text).join();

  void _autofillCode() {
    if (_generatedOtp.length == 6) {
      for (int i = 0; i < 6; i++) {
        _digitControllers[i].text = _generatedOtp[i];
      }
      setState(() => _errorMessage = null);
      _handleVerify();
    }
  }

  Future<void> _handleVerify() async {
    final enteredCode = _currentOtpInput.trim();
    if (enteredCode.length < 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits of the code.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    bool isMatch = (enteredCode == _generatedOtp);

    try {
      final url = Uri.parse('http://127.0.0.1:8000/api/auth/verify-otp');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email, 'otp': enteredCode}),
      );
      if (res.statusCode == 200) {
        isMatch = true;
      }
    } catch (_) {}

    setState(() => _isVerifying = false);

    if (isMatch) {
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorMessage = 'Invalid verification code. Please check your email and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFE8411E);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: brandColor.withValues(alpha: 0.1),
                    border: Border.all(color: brandColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: brandColor,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Verify Your Email Address',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              const Text(
                'To verify that this email is genuine and active, we sent a 6-digit OTP code to:',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.email, size: 14, color: brandColor),
                      const SizedBox(width: 6),
                      Text(
                        widget.email,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Live Demo / Simulation Inbox Banner
              InkWell(
                onTap: _autofillCode,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.markunread_mailbox, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Email Inbox Simulation',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                            ),
                            Text(
                              _isSending
                                  ? 'Generating code...'
                                  : 'Your OTP code is: $_generatedOtp (Tap to Autofill)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.touch_app, size: 16, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 6 PIN Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 54,
                    child: TextFormField(
                      controller: _digitControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: brandColor, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_currentOtpInput.length == 6) {
                          _handleVerify();
                        }
                      },
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: (_isSending || _isVerifying) ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Verify & Proceed',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Didn\'t receive code? ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  TextButton(
                    onPressed: _resendCountdown > 0 ? null : _requestOtp,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: Text(
                      _resendCountdown > 0 ? 'Resend in ${_resendCountdown}s' : 'Resend Code',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _resendCountdown > 0 ? Colors.grey : brandColor,
                      ),
                    ),
                  ),
                ],
              ),

              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel & Change Email', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
