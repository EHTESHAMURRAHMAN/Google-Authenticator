import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:googleauth/G-Authenticator/Controllers/G-Auth-Controllers.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class GauthView extends GetView<GauthController> {
  GauthView({super.key});
  GauthController controller = Get.put(GauthController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Google Authenticator',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          // Show loading indicator while secretKey is null
          if (controller.secretKey?.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // Image.asset(
                    //   'assets/icons/auth.png',
                    //   height: MediaQuery.of(context).size.height / 10,
                    // ),

                    SizedBox(height: MediaQuery.of(context).size.height / 15),

                    const Text(
                      "Secure Your Account with Google Authenticator",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Use Google Authenticator to generate a time-based one-time password (OTP) for added security. Enter the OTP displayed on your authenticator app to verify your account.",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: MediaQuery.of(context).size.height / 15),

                    // OTP input field
                    TextFormField(
                      controller: controller.otpController,
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          width: MediaQuery.of(context).size.width / 6,
                          child: const Center(
                            child: Text(
                              'G -',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        labelText: "Enter OTP",
                        labelStyle:
                            TextStyle(color: Theme.of(context).primaryColor),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                            borderRadius: BorderRadius.circular(20)),
                        border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 20),

                    // Instruction for getting the key
                    InkWell(
                      onTap: () {
                        bottomsheet(context);
                      },
                      child: Text(
                        "Don't have a key? Tap here to set up Google Authenticator.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Validate OTP button
              ElevatedButton(
                onPressed: controller.validateOTP,
                child: const Text(
                  "Validate OTP",
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  bottomsheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).canvasColor,
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.copy, color: Colors.transparent),
                  Text(
                    "Scan QR or Copy Key",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor),
                  ),
                  InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: const Icon(Icons.cancel, color: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Scan the QR code or copy the key to set up Google Authenticator.",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              QrImageView(
                data: controller.getTOTPURI(),
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: controller.secretKey!.value));
                  Get.snackbar("Key Copied", "Copied to clipboard.",
                      snackPosition: SnackPosition.BOTTOM);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${controller.secretKey?.value}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.copy, color: Theme.of(context).primaryColor),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  launchUrl(Uri.parse(
                      "https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2"));
                },
                icon:
                    Icon(Icons.download, color: Theme.of(context).primaryColor),
                label: Text(
                  "Don't have it? Download from Google Play Store",
                  style: TextStyle(
                      fontSize: 13, color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
