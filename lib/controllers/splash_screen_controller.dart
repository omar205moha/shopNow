import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/utils/constant.dart';

class SplashScreenController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    _startSplash();
  }

  void _startSplash() async {
    await Future.delayed(const Duration(seconds: 2));
    checkAuthState();
  }

  void checkAuthState() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        if (getUserType == null) {
          Get.offAllNamed(AppPageNames.loginScreen);
        } else {
          switch (getUserType) {
            case 'admin':
              Get.offAllNamed(AppPageNames.adminDashboardScreen);
              break;
            case 'seller':
              Get.offAllNamed(AppPageNames.shopManagementScreen);
              break;
            // case 'buyer':
            //   Get.offAllNamed(AppPageNames.homeScreen);
            //   break;
            case 'shopper':
              Get.offAllNamed(AppPageNames.shopperDashboardScreen);
              break;
            case 'buyer':
            default:
              Get.offAllNamed(AppPageNames.homeScreen);
          }
        }
      } else {
        Get.offNamed(AppPageNames.introScreen);
      }
    });
  }
}
