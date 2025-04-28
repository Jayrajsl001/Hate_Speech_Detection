import 'package:flutter/material.dart';
import 'package:hate_speech/DBhelper/mongodb.dart';
// import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:flutter/services.dart';
import 'package:hate_speech/Utils/themeProvider.dart';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

// MongoDB connection string & collection
const COLLECTION_NAME = "users";

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SignUpScreen(),
  ));
}

// SignUp Screen
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final _isDarkMode = themeProvider.isDarkMode;
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              setState(() {
                themeProvider.toggleTheme();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_sharp,
                    size: 80, color: Colors.blueAccent),
                const SizedBox(height: 10),
                Card(
                  color: _isDarkMode ? Colors.grey[850] : Colors.white,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create an account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Words matter. Let’s create a safer space together!',
                          style: TextStyle(
                              fontSize: 14,
                              color: _isDarkMode
                                  ? Colors.grey[400]
                                  : Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          style: TextStyle(),
                          controller: _nameController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^[a-zA-Z\s]+$'))
                          ],
                          decoration: InputDecoration(
                            labelText: 'Name',
                            labelStyle: TextStyle(
                                color:
                                    _isDarkMode ? Colors.white : Colors.black),
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _ageController,
                          keyboardType:
                              TextInputType.number, // Allow only numbers
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly, // Allow only digits (0-9)
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              int? age = int.tryParse(value);
                              if (age == null || age >= 90) {
                                _ageController.text =
                                    ""; // Clear input if invalid
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Please enter a valid age below 90."),
                                  ),
                                );
                              }
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Age',
                            labelStyle: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(
                              color: _isDarkMode ? Colors.white : Colors.black,
                            ),
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onChanged: (value) async {
                            if (value.isNotEmpty) {
                              final existingUser = await mongodb.userCollection
                                  .findOne({'email': value});
                              if (existingUser != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          " An Account with this gmail already exists!")),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtpScreen(
                                    email: _emailController.text,
                                    name: _nameController.text,
                                    age: _ageController.text,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            child: Text('Send OTP',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: _isDarkMode
                                        ? Colors.white
                                        : Colors.black)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// OTP Screen
class OtpScreen extends StatefulWidget {
  final String email, name, age;
  const OtpScreen(
      {super.key, required this.email, required this.name, required this.age});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  String _generatedOtp = "";
  bool _isOtpValid = false;

  @override
  void initState() {
    super.initState();
    _generateOtpAndSend(widget.email);
  }

  String _generateOtp() {
    return (Random().nextInt(900000) + 100000).toString();
  }

  Future<void> _generateOtpAndSend(String email) async {
    _generatedOtp = _generateOtp();
    _isOtpValid = true;

    String username = 'your_mail_id';
    String password = 'your_mail_password';
    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = Address(username, 'Your App')
      ..recipients.add(email)
      ..subject = 'Your OTP Code'
      ..text = 'Your OTP code is: $_generatedOtp';

    try {
      await send(message, smtpServer);
      print('OTP sent: $_generatedOtp');
    } catch (e) {
      print('Message not sent. $e');
    }
  }

  bool _validateOtp(String otp) {
    return _isOtpValid && otp == _generatedOtp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _otpController,
              keyboardType: TextInputType.number,
              onCompleted: (value) {
                if (_validateOtp(value)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PasswordScreen(
                            name: widget.name,
                            age: widget.age,
                            email: widget.email)),
                  );
                } else {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Invalid OTP')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Password Screen
class PasswordScreen extends StatefulWidget {
  final String name, age, email;
  const PasswordScreen(
      {super.key, required this.name, required this.age, required this.email});

  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _saveToMongoDB() async {
    try {
      // Creating a map with user details
      Map<String, dynamic> userData = {
        "name": widget.name,
        "age": widget.age,
        "email": widget.email,
        "password": _passwordController.text,
      };

      // Calling the insertData function from mongodb.dart
      await mongodb.insertData(userData);

      print('Data inserted successfully');
    } catch (e) {
      print('Error inserting data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Set Password',
                  labelStyle: TextStyle(color: Colors.blue),
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Conform Password',
                  labelStyle: TextStyle(color: Colors.blue),
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_passwordController.text ==
                      _confirmPasswordController.text) {
                    await _saveToMongoDB();
                    Navigator.popUntil(context, ModalRoute.withName('/'));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Passwords do not match')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Set Password & Login',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
