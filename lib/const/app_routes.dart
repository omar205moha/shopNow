import 'package:get/get.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';
import 'package:shop_now_mobile/screens/changeAddressScreen.dart';
import 'package:shop_now_mobile/screens/unknown_screen.dart';

import '../screens/aboutScreen.dart';
import '../screens/checkoutScreen.dart';
import '../screens/dessertScreen.dart';
import '../screens/forgetPwScreen.dart';
import '../screens/homeScreen.dart';
import '../screens/inboxScreen.dart';
import '../screens/individualItem.dart';
import '../screens/introScreen.dart';
import '../screens/landingScreen.dart';
import '../screens/login_screen.dart';
import '../screens/menuScreen.dart';
import '../screens/moreScreen.dart';
import '../screens/myOrderScreen.dart';
import '../screens/newPwScreen.dart';
import '../screens/notificationScreen.dart';
import '../screens/offerScreen.dart';
import '../screens/paymentScreen.dart';
import '../screens/profile_screen.dart';
import '../screens/sentOTPScreen.dart';
import '../screens/signUpScreen.dart';
import '../screens/splashScreen.dart';

class AppPages {
  static final List<GetPage<dynamic>> pages = [
    GetPage(name: AppPageNames.splashScreen, page: () => const SplashScreen()),
    GetPage(name: AppPageNames.landingScreen, page: () => const LandingScreen()),
    GetPage(name: AppPageNames.loginScreen, page: () => const LoginScreen()),
    GetPage(name: AppPageNames.signUpScreen, page: () => SignUpScreen()),
    GetPage(name: AppPageNames.forgetPwScreen, page: () => const ForgetPwScreen()),
    GetPage(name: AppPageNames.sendOTPScreen, page: () => const SendOTPScreen()),
    GetPage(name: AppPageNames.newPwScreen, page: () => const NewPwScreen()),
    GetPage(name: AppPageNames.introScreen, page: () => const IntroScreens()),
    GetPage(name: AppPageNames.homeScreen, page: () => const HomeScreen()),
    GetPage(name: AppPageNames.menuScreen, page: () => const MenuScreen()),
    GetPage(name: AppPageNames.offerScreen, page: () => OfferScreen()),
    GetPage(name: AppPageNames.profileScreen, page: () => ProfileScreen()),
    GetPage(name: AppPageNames.moreScreen, page: () => MoreScreen()),
    GetPage(name: AppPageNames.dessertScreen, page: () => const DessertScreen()),
    GetPage(name: AppPageNames.individualItemScreen, page: () => const IndividualItem()),
    GetPage(name: AppPageNames.paymentScreen, page: () => const PaymentScreen()),
    GetPage(name: AppPageNames.notificationsScreen, page: () => NotificationScreen()),
    GetPage(name: AppPageNames.aboutScreen, page: () => AboutScreen()),
    GetPage(name: AppPageNames.inboxScreen, page: () => InboxScreen()),
    GetPage(name: AppPageNames.myOrderScreen, page: () => const MyOrderScreen()),
    GetPage(name: AppPageNames.checkoutScreen, page: () => const CheckoutScreen()),
    GetPage(name: AppPageNames.changeAddressScreen, page: () => const ChangeAddressScreen()),
  ];

  static final GetPage<dynamic> unknownScreenPageRoute =
      GetPage(name: AppPageNames.unknownScreen, page: () => const UnknownScreen());
}
