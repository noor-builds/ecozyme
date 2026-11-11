import 'package:ecoenzyme/core/router/app_router.dart';
import 'package:ecoenzyme/core/theme/theme.dart';
import 'package:ecoenzyme/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _selectedLanguage = 'en';
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  bool _isLoading = false;

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
      'title1': 'Register,',
      'title2': 'To Grow',
      'nameHint': 'name',
      'emailHint': 'email',
      'mobileHint': 'mobile no.',
      'registerButton': 'Register',
      'accountText': 'Already have an account? ',
      'signIn': 'Login',
    },
    'hi': {
      'title1': 'रजिस्टर,',
      'title2': 'बढ़ने के लिए',
      'nameHint': 'नाम',
      'emailHint': 'ईमेल',
      'mobileHint': 'मोबाइल नंबर',
      'registerButton': 'रजिस्टर',
      'accountText': 'क्या आपका अकाउंट पहले से है? ',
      'signIn': 'लॉगिन',
    },
    'bn': {
      'title1': 'নিবন্ধন,',
      'title2': 'বড় হতে',
      'nameHint': 'নাম',
      'emailHint': 'ইমেল',
      'mobileHint': 'মোবাইল নম্বর',
      'registerButton': 'নিবন্ধন',
      'accountText': 'ইতোমধ্যে একটি অ্যাকাউন্ট আছে? ',
      'signIn': 'লগইন',
    },
    'ta': {
      'title1': 'பதிவு,',
      'title2': 'வளர',
      'nameHint': 'பெயர்',
      'emailHint': 'மின்னஞ்சல்',
      'mobileHint': 'மொபைல் எண்',
      'registerButton': 'பதிவு',
      'accountText': 'ஏற்கனவே ஒரு கணக்கு உண்டா? ',
      'signIn': 'உள்நுழைக',
    },
    'te': {
      'title1': 'నమోదు,',
      'title2': 'వింటి',
      'nameHint': 'పేరు',
      'emailHint': 'ఇమెయిల్',
      'mobileHint': 'మొబైల్ నెంబర్',
      'registerButton': 'రిజిస్టర్',
      'accountText': 'ఇప్పుడే అకౌంట్ ఉందా? ',
      'signIn': 'లాగిన్',
    },
    'mr': {
      'title1': 'नोंदणी,',
      'title2': 'वाढण्यासाठी',
      'nameHint': 'नाव',
      'emailHint': 'ईमेल',
      'mobileHint': 'मोबाईल क्र.',
      'registerButton': 'नोंदणी',
      'accountText': 'आधीच खाते आहे का? ',
      'signIn': 'लॉगिन',
    },
    'kn': {
      'title1': 'ನೋಂದಣಿ,',
      'title2': 'ಹೆಚ್ಚಾಗಲು',
      'nameHint': 'ಹೆಸರು',
      'emailHint': 'ಇಮೇಲ್',
      'mobileHint': 'ಮೊಬೈಲ್ ಸಂಖ್ಯೆ',
      'registerButton': 'ನೋಂದಣಿ',
      'accountText': 'ಈಗಾಗಲೇ ಖಾತೆ ಇದೆಯೇ? ',
      'signIn': 'ಲಾಗಿನ್',
    },
    'ml': {
      'title1': 'രജിസ്റ്റർ,',
      'title2': 'വളരാൻ',
      'nameHint': 'പേര്',
      'emailHint': 'ഇമെയിൽ',
      'mobileHint': 'മൊബൈൽ നമ്പർ',
      'registerButton': 'രജിസ്റ്റർ',
      'accountText': 'ഇതിനകം ഒരു അക്കൗണ്ട് ഉണ്ടോ? ',
      'signIn': 'ലോഗിൻ',
    },
  };

  Map<String, String> get _currentText => _translations[_selectedLanguage]!;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleRegister() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final mobile = mobileController.text.trim();

    if (name.isEmpty || email.isEmpty || mobile.isEmpty) {
      _showSnackBar('Please enter your name, email, and mobile number.');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService().registerUser(
      name: name,
      email: email,
      mobile: mobile,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (!result.isSuccess) {
      _showSnackBar(result.message);
      return;
    }

    context.push(
      Uri(
        path: AppRoutes.otp,
        queryParameters: {'email': email, 'type': OtpType.signup.name},
      ).toString(),
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
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: _currentText['nameHint'],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        obscureText: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: _currentText['emailHint'],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        obscureText: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: mobileController,
                        decoration: InputDecoration(
                          hintText: _currentText['mobileHint'],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        obscureText: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_currentText['registerButton']!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentText['accountText']!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.go(AppRoutes.login);
                            },
                            child: Text(
                              _currentText['signIn']!,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
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
