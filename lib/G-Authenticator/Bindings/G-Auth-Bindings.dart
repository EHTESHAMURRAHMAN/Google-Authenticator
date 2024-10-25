import 'package:get/get.dart';
import 'package:googleauth/G-Authenticator/Controllers/G-Auth-Controllers.dart';

class GauthBindings extends Bindings {
  @override
  void dependencies() {
    Get.put<GauthController>(GauthController());
  }
}
