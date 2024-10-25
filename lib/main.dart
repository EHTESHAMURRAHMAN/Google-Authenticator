import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:base32/base32.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Authenticator OTP Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: OTPPage(),
    );
  }
}

class OTPPage extends StatefulWidget {
  @override
  _OTPPageState createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  late String secretKey;
  late Stream<String> otpStream;
  late StreamSubscription<String> _twoFASubscription;
  String _currentOtp = "";
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    secretKey = _generateSecretKey();

    // Initialize the OTP stream to generate an OTP every 30 seconds
    otpStream = Stream<String>.periodic(
      const Duration(seconds: 30),
      (_) => OTP.generateTOTPCodeString(
        secretKey,
        DateTime.now().millisecondsSinceEpoch,
        length: 6,
        interval: 30,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      ),
    ).asBroadcastStream();

    // Listen to the OTP stream
    _twoFASubscription = otpStream.listen((event) {
      setState(() {
        _currentOtp = event;
      });
    });
  }

  @override
  void dispose() {
    _twoFASubscription.cancel();
    _otpController.dispose();
    super.dispose();
  }

  String _generateSecretKey({int length = 16}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base32.encode(Uint8List.fromList(bytes)).replaceAll('=', '');
  }

  void _validateOTP() {
    final expectedOtp = OTP.generateTOTPCodeString(
      secretKey,
      DateTime.now().millisecondsSinceEpoch,
      interval: 30,
      length: 6,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );

    final enteredCode = _otpController.text.trim(); // Trim whitespace
    if (expectedOtp == enteredCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP is valid!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP!")),
      );
    }
  }

  String _getTOTPURI() {
    String appName = "YourAppName"; // Replace with your app name
    String userName = "your_email@example.com";
    return "otpauth://totp/$appName:$userName?secret=$secretKey&issuer=$appName&period=30";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Authenticator OTP Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Generated Secret Key: $secretKey",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Current OTP: $_currentOtp", // Updated to show current OTP
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _validateOTP,
              child: const Text("Validate OTP"),
            ),
            const SizedBox(height: 30),
            Center(
              child: QrImageView(
                data: _getTOTPURI(),
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Scan this QR code in Google Authenticator",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
