import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hate_speech/DBhelper/mongodb.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ForgotPasswordScreen(),
  ));
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();

  /// Generates and sends OTP via email
  void sendOtp() async {
    String enteredEmail = emailController.text.trim();
    if (enteredEmail.isEmpty) {
      showSnackBar('Please enter your email address.');
      return;
    }

    // Generate a 6-digit OTP
    String generatedOtp = (Random().nextInt(900000) + 100000).toString();

    // Store OTP securely with expiration time
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('otp', generatedOtp);
    await prefs.setInt(
        'otp_expiry', DateTime.now().millisecondsSinceEpoch + (3 * 60 * 1000));
    await prefs.setString('email', enteredEmail); // Store email

    try {
      String username = 'kachhimaharshi20@gmail.com';
      String password = 'ayzv ebqr vvpx rcoz';
      final smtpServer = gmail(username, password);

      final message = Message()
        ..from = Address(username, 'Hate Speech Detection')
        ..recipients.add(enteredEmail)
        ..subject = 'Your OTP Code'
        ..text =
            'Your OTP code is: $generatedOtp\nThis code is valid for  minutes.';

      await send(message, smtpServer);
      showSnackBar('OTP sent to your email!');

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(email: enteredEmail)),
      );
    } catch (e) {
      showSnackBar('Failed to send OTP: $e');
    }
  }

  void showSnackBar(String message) {
    if (!mounted) return; // Exit if the widget is not mounted
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendOtp,
              child: const Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({required this.email, super.key});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController otpController = TextEditingController();

  //verify otp
  void verifyOtp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedOtp = prefs.getString('otp');
    int? expiryTime = prefs.getInt('otp_expiry');

    if (storedOtp == null ||
        expiryTime == null ||
        DateTime.now().millisecondsSinceEpoch > expiryTime) {
      showSnackBar('OTP expired. Please request a new one.');
      return;
    }

    if (otpController.text.trim() == storedOtp) {
      showSnackBar('OTP verified successfully!');

      // Navigate to Reset Password screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: widget.email)),
      );
    } else {
      showSnackBar('Incorrect OTP. Try again.');
    }
  }

  /// Displays Snackbar Message
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Enter the OTP sent to your email'),
            const SizedBox(height: 20),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: otpController,
              keyboardType: TextInputType.number,
              onChanged: (value) {},
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: verifyOtp,
              child: const Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({required this.email, super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  /// ✅ **Resets Password in MongoDB**
  void resetPassword() async {
    String newPassword = newPasswordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      showSnackBar('Please fill both fields.');
      return;
    }

    if (newPassword != confirmPassword) {
      showSnackBar('Passwords do not match.');
      return;
    }

    // Update password in MongoDB
    await mongodb.updatePassword(widget.email, newPassword);
    showSnackBar('Password reset successfully!');

    // Navigate back to login screen
    Navigator.popUntil(context, ModalRoute.withName('/'));
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: resetPassword,
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}
