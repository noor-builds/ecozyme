import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<AuthResult> registerUser({
    required String name,
    required String email,
    required String mobile,
  }) async {
    try {
      await supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
        data: {'name': name, 'mobile': mobile},
      );

      return AuthResult.success();
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('AuthException: ${e.message}');
      }
      return AuthResult.failure(e.message);
    } catch (e) {
      if (kDebugMode) {
        print('Error registering user: $e');
      }
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  Future<AuthResult> loginUser(String email) async {
  try {
    // Correct usage of signInWithOtp for passwordless email login
    await supabase.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
    return AuthResult.success();
  } on AuthException catch (e) {
    if (kDebugMode) {
      print('AuthException: ${e.message}');
    }
    return AuthResult.failure(e.message);
  } catch (e) {
    if (kDebugMode) {
      print('Error logging in user: $e');
    }
    return AuthResult.failure('Something went wrong. Please try again.');
  }
}
  Future<AuthResult> resendOtp({
    required String email,
    required OtpType type,
  }) async {
    try {
      if (type == OtpType.signup) {
        await supabase.auth.resend(email: email, type: type);
      } else {
        await supabase.auth.signInWithOtp(
          email: email,
          shouldCreateUser: false,
        );
      }

      return AuthResult.success();
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('AuthException: ${e.message}');
      }
      return AuthResult.failure(e.message);
    } catch (e) {
      if (kDebugMode) {
        print('Error resending OTP: $e');
      }
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  Future<AuthResult> verifyOtp({
    required String email,
    required String otp,
    required OtpType type,
  }) async {
    try {
      final response = await supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: type,
      );

      if (response.user != null) {
        return AuthResult.success();
      }

      return AuthResult.failure('Invalid OTP. Please try again.');
    } on AuthException catch (e) {
      if (kDebugMode) {
        print('AuthException: ${e.message}');
      }
      return AuthResult.failure(e.message);
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying OTP: $e');
      }
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }
}

class AuthResult {
  const AuthResult._({required this.isSuccess, required this.message});

  final bool isSuccess;
  final String message;

  factory AuthResult.success([String message = 'success']) {
    return AuthResult._(isSuccess: true, message: message);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, message: message);
  }
}
