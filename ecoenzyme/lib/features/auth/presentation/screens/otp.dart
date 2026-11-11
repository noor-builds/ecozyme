import 'package:ecoenzyme/core/theme/theme.dart';
import 'package:ecoenzyme/core/router/app_router.dart';
import 'package:ecoenzyme/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.email});

  final String email;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _selectedLanguage = 'en';
  final otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;

  static const Map<String, String> _languageNames = {
    'en': 'English',
    'hi': 'हिन्दी',
    'bn': 'বাংলা',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'mr': 'मराठी',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
  };

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'title1': 'Verify,',
      'title2': 'Your OTP',
      'otpHint': 'Enter OTP',
      'verifyButton': 'Verify',
      'resend': 'Resend code',
    },
    'hi': {
      'title1': 'पुष्टि करें,',
      'title2': 'आपका OTP',
      'otpHint': 'OTP दर्ज करें',
      'verifyButton': 'सत्यापित करें',
      'resend': 'कोड पुनः भेजें',
    },
    'bn': {
      'title1': 'যাচাই করুন,',
      'title2': 'আপনার OTP',
      'otpHint': 'OTP লিখুন',
      'verifyButton': 'যাচাই করুন',
      'resend': 'কোড পুনরায় পাঠান',
    },
    'ta': {
      'title1': 'சரிபார்,',
      'title2': 'உங்கள் OTP',
      'otpHint': 'OTP உள்ளிடவும்',
      'verifyButton': 'சரிபார்',
      'resend': 'கோڈை மீண்டும் அனுப்பவும்',
    },
    'te': {
      'title1': 'నిర్ధారించండి,',
      'title2': 'మీ OTP',
      'otpHint': 'OTP నమోదు చేయండి',
      'verifyButton': 'నిర్ధారించండి',
      'resend': 'కోడ్ మళ్లీ పంపండి',
    },
    'mr': {
      'title1': 'पहाणी करा,',
      'title2': 'आपला OTP',
      'otpHint': 'OTP प्रविष्ट करा',
      'verifyButton': 'पाहणी करा',
      'resend': 'कोड पुन्हा पाठवा',
    },
    'kn': {
      'title1': 'ತಿಳಿಸಿ,',
      'title2': 'ನಿಮ್ಮ OTP',
      'otpHint': 'OTP ನಮೂದಿಸಿ',
      'verifyButton': 'ತಿಳಿಸಿ',
      'resend': 'ಕೋಡ್ ಮರುಪ್ರದಾನ ಮಾಡಿ',
    },
    'ml': {
      'title1': 'പരിശോധിക്കുക,',
      'title2': 'നിങ്ങളുടെ OTP',
      'otpHint': 'OTP നൽകുക',
      'verifyButton': 'പരിശോധിക്കുക',
      'resend': 'കോഡ് വീണ്ടും അയക്കുക',
    },
  };

  Map<String, String> get _currentText => _translations[_selectedLanguage]!;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1B4332),
      ),
    );
  }

  Future<void> _handleVerifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      _showSnackBar('Please enter the OTP sent to ${widget.email}.');
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final result = await AuthService().verifyOtp(
      email: widget.email,
      otp: otp,
      type: OtpType.email,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isVerifying = false;
    });

    if (!result.isSuccess) {
      _showSnackBar(result.message);
      context.go(AppRoutes.login);
      return;
    }

    _showSnackBar('OTP verified successfully.');
    context.go(AppRoutes.home);
  }

  Future<void> _handleResendOtp() async {
    setState(() {
      _isResending = true;
    });

    final result = await AuthService().resendOtp(
      email: widget.email,
      type: OtpType.email,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isResending = false;
    });

    _showSnackBar(
      result.isSuccess ? 'OTP sent again to ${widget.email}.' : result.message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      borderRadius: BorderRadius.circular(12),
                      items: _languageNames.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLanguage = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _currentText['title1']!,
                      style: AppTheme.lightTheme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentText['title2']!,
                      style: AppTheme.lightTheme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: otpController,
                        decoration: InputDecoration(
                          hintText: _currentText['otpHint'],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _handleVerifyOtp,
                        child: _isVerifying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_currentText['verifyButton']!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isResending ? null : _handleResendOtp,
                      child: Text(
                        _isResending ? 'Sending...' : _currentText['resend']!,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
