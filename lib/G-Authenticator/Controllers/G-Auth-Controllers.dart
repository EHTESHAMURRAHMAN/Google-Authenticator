import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:otp/otp.dart';
import 'package:base32/base32.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GauthController extends GetxController {
  RxString? secretKey = RxString(''); // Secret key as an observable
  RxString currentOtp = "".obs; // Current OTP as an observable
  StreamSubscription<String>? _twoFASubscription;
  final otpController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _initializeOTP();
  }

  Future<void> _initializeOTP() async {
    await _initializeSecretKey();

    // Initialize the OTP stream only if secretKey is set
    if (secretKey != null) {
      Stream<String> otpStream = Stream<String>.periodic(
        const Duration(seconds: 30),
        (_) => OTP.generateTOTPCodeString(
          secretKey!.value,
          DateTime.now().millisecondsSinceEpoch,
          length: 6,
          interval: 30,
          algorithm: Algorithm.SHA1,
          isGoogle: true,
        ),
      ).asBroadcastStream();

      // Listen to the OTP stream
      _twoFASubscription = otpStream.listen((event) {
        currentOtp.value = event;
      });
    }
  }

  Future<void> _initializeSecretKey() async {
    final prefs = await SharedPreferences.getInstance();
    final storedKey = prefs.getString('secretKey');

    if (storedKey != null) {
      secretKey?.value = storedKey;
    } else {
      secretKey?.value = _generateSecretKey();
      await prefs.setString('secretKey', secretKey!.value);
    }
  }

  String _generateSecretKey({int length = 16}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base32.encode(Uint8List.fromList(bytes)).replaceAll('=', '');
  }

  void validateOTP() {
    if (secretKey?.value == null) return;

    final expectedOtp = OTP.generateTOTPCodeString(
      secretKey!.value,
      DateTime.now().millisecondsSinceEpoch,
      interval: 30,
      length: 6,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );

    final enteredCode = otpController.text.trim();
    if (expectedOtp == enteredCode) {
      Get.snackbar('Congrates!', 'OTP is valid');
    } else {
      Get.snackbar('Oops!', 'OTP is not valid');
    }
  }

  String getTOTPURI() {
    String appName = "AfricaCrypto"; // Replace with your app name

    return "otpauth://totp/$appName?secret=${secretKey?.value}&issuer=$appName&period=30";
  }

  @override
  void onClose() {
    _twoFASubscription?.cancel();
    otpController.dispose();
    super.onClose();
  }
}
