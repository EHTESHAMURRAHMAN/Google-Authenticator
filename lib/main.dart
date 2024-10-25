import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleauth/G-Authenticator/Views/G-Auth-Views.dart';
import 'package:otp/otp.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:base32/base32.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(GauthView());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Authenticator OTP Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const OTPPage(),
    );
  }
}

class OTPPage extends StatefulWidget {
  const OTPPage({super.key});

  @override
  _OTPPageState createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  String? secretKey;
  late Stream<String> otpStream;
  StreamSubscription<String>? _twoFASubscription;
  String _currentOtp = "";
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeOTP();
  }

  Future<void> _initializeOTP() async {
    await _initializeSecretKey();

    // Initialize the OTP stream only if secretKey is set
    if (secretKey != null) {
      otpStream = Stream<String>.periodic(
        const Duration(seconds: 30),
        (_) => OTP.generateTOTPCodeString(
          secretKey!,
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
  }

  Future<void> _initializeSecretKey() async {
    final prefs = await SharedPreferences.getInstance();
    final storedKey = prefs.getString('secretKey');

    if (storedKey != null) {
      secretKey = storedKey;
    } else {
      secretKey = _generateSecretKey();
      await prefs.setString('secretKey', secretKey!);
    }
    setState(() {}); // Trigger a rebuild once secretKey is initialized
  }

  @override
  void dispose() {
    _twoFASubscription?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  String _generateSecretKey({int length = 16}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base32.encode(Uint8List.fromList(bytes)).replaceAll('=', '');
  }

  void _validateOTP() {
    if (secretKey == null) return;

    final expectedOtp = OTP.generateTOTPCodeString(
      secretKey!,
      DateTime.now().millisecondsSinceEpoch,
      interval: 30,
      length: 6,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );

    final enteredCode = _otpController.text.trim();
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
    // Show loading indicator while secretKey is null
    if (secretKey == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Google Authenticator OTP Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: secretKey!));
              },
              child: Text(
                "Generated Secret Key: $secretKey",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Current OTP: $_currentOtp",
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


// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:otp/otp.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:base32/base32.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Google Authenticator OTP Demo',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const OTPPage(),
//     );
//   }
// }

// class OTPPage extends StatefulWidget {
//   const OTPPage({super.key});

//   @override
//   _OTPPageState createState() => _OTPPageState();
// }

// class _OTPPageState extends State<OTPPage> {
//   late String secretKey;
//   late Stream<String> otpStream;
//   late StreamSubscription<String> _twoFASubscription;
//   String _currentOtp = "";
//   final TextEditingController _otpController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     secretKey = _generateSecretKey();

//     // Initialize the OTP stream to generate an OTP every 30 seconds
//     otpStream = Stream<String>.periodic(
//       const Duration(seconds: 30),
//       (_) => OTP.generateTOTPCodeString(
//         secretKey,
//         DateTime.now().millisecondsSinceEpoch,
//         length: 6,
//         interval: 30,
//         algorithm: Algorithm.SHA1,
//         isGoogle: true,
//       ),
//     ).asBroadcastStream();

//     // Listen to the OTP stream
//     _twoFASubscription = otpStream.listen((event) {
//       setState(() {
//         _currentOtp = event;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _twoFASubscription.cancel();
//     _otpController.dispose();
//     super.dispose();
//   }

//   String _generateSecretKey({int length = 16}) {
//     final random = Random.secure();
//     final bytes = List<int>.generate(length, (_) => random.nextInt(256));
//     return base32.encode(Uint8List.fromList(bytes)).replaceAll('=', '');
//   }

//   void _validateOTP() {
//     final expectedOtp = OTP.generateTOTPCodeString(
//       secretKey,
//       DateTime.now().millisecondsSinceEpoch,
//       interval: 30,
//       length: 6,
//       algorithm: Algorithm.SHA1,
//       isGoogle: true,
//     );

//     final enteredCode = _otpController.text.trim(); // Trim whitespace
//     if (expectedOtp == enteredCode) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("OTP is valid!")),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Invalid OTP!")),
//       );
//     }
//   }

//   String _getTOTPURI() {
//     String appName = "YourAppName"; // Replace with your app name
//     String userName = "your_email@example.com";
//     return "otpauth://totp/$appName:$userName?secret=$secretKey&issuer=$appName&period=30";
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Google Authenticator OTP Demo')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: ListView(
//           children: [
//             InkWell(
//               onTap: () {
//                 Clipboard.setData(ClipboardData(text: secretKey));
//               },
//               child: Text(
//                 "Generated Secret Key: $secretKey",
//                 style:
//                     const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               "Current OTP: $_currentOtp", // Updated to show current OTP
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             TextFormField(
//               controller: _otpController,
//               decoration: const InputDecoration(
//                 labelText: "Enter OTP",
//                 border: OutlineInputBorder(),
//               ),
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _validateOTP,
//               child: const Text("Validate OTP"),
//             ),
//             const SizedBox(height: 30),
//             Center(
//               child: QrImageView(
//                 data: _getTOTPURI(),
//                 version: QrVersions.auto,
//                 size: 200.0,
//                 gapless: false,
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "Scan this QR code in Google Authenticator",
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 16),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
