import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shop_now_mobile/const/app_routes.dart';
import 'package:shop_now_mobile/const/app_theme.dart';
import 'package:shop_now_mobile/controllers/main_cart_controller.dart';
import 'package:shop_now_mobile/firebase_options.dart';
import 'package:shop_now_mobile/screens/adminDashboardScreen.dart';
import 'package:shop_now_mobile/screens/changeAddressScreen.dart';
import 'package:shop_now_mobile/screens/myOrdersScreen.dart';
import 'package:shop_now_mobile/screens/orderTrackingScreen.dart';
import 'package:shop_now_mobile/screens/paymentTestScreen.dart';
import 'package:shop_now_mobile/screens/seedDataScreen.dart';
import 'package:shop_now_mobile/screens/shopListScreen.dart';
import 'package:shop_now_mobile/screens/shopManagementScreen.dart';
import 'package:shop_now_mobile/screens/shopProductsScreen.dart';
import 'package:shop_now_mobile/screens/shopperDashboardScreen.dart';
import 'package:shop_now_mobile/screens/testScreen.dart';
import 'package:toastification/toastification.dart';
import './screens/splashScreen.dart';
import './screens/landingScreen.dart';
import './screens/login_screen.dart';
import './screens/signUpScreen.dart';
import './screens/forgetPwScreen.dart';
import './screens/sentOTPScreen.dart';
import './screens/newPwScreen.dart';
import './screens/introScreen.dart';
import './screens/homeScreen.dart';
import './screens/menuScreen.dart';
import './screens/moreScreen.dart';
import './screens/offerScreen.dart';
import './screens/profile_screen.dart';
import './screens/dessertScreen.dart';
import './screens/individualItem.dart';
import './screens/paymentScreen.dart';
import './screens/notificationScreen.dart';
import './screens/aboutScreen.dart';
import './screens/inboxScreen.dart';
import './screens/myOrderScreen.dart';
import './screens/checkoutScreen.dart';
import 'const/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  Stripe.publishableKey = dotenv.env['PUBLISHABLE_KEY'] ?? '';
  await Stripe.instance.applySettings();
  await GetStorage.init();
  await GoogleSignIn().signInSilently(); // Ensure Google Sign-In is initialized
  Get.put(MainCartController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ShopNow',
        theme: AppTheme.lightTheme(),
        /*
        ThemeData(
          fontFamily: "Metropolis",
          primarySwatch: Colors.red,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(
                AppColors.orangeColor,
              ),
              shape: WidgetStateProperty.all(
                const StadiumBorder(),
              ),
              elevation: WidgetStateProperty.all(0),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(
                AppColors.orangeColor,
              ),
            ),
          ),
          textTheme: const TextTheme(
            headlineSmall: TextStyle(
              color: AppColors.greyDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            headlineMedium: TextStyle(
              color: AppColors.greyLight,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            headlineLarge: TextStyle(
              color: AppColors.greyDark,
              fontWeight: FontWeight.normal,
              fontSize: 25,
            ),
            titleLarge: TextStyle(
              color: AppColors.greyDark,
              fontSize: 25,
            ),
            bodyMedium: TextStyle(
              color: AppColors.greyLight,
            ),
          ),
        ),
     */
        getPages: AppPages.pages,
        unknownRoute: AppPages.unknownScreenPageRoute,
        home: const SplashScreen(),
        routes: {
          SplashScreen.routeName: (context) => const SplashScreen(),
          LandingScreen.routeName: (context) => const LandingScreen(),
          LoginScreen.routeName: (context) => const LoginScreen(),
          SignUpScreen.routeName: (context) => SignUpScreen(),
          ForgetPwScreen.routeName: (context) => const ForgetPwScreen(),
          SendOTPScreen.routeName: (context) => const SendOTPScreen(),
          NewPwScreen.routeName: (context) => const NewPwScreen(),
          IntroScreens.routeName: (context) => const IntroScreens(),
          HomeScreen.routeName: (context) => const HomeScreen(),
          MenuScreen.routeName: (context) => const MenuScreen(),
          OfferScreen.routeName: (context) => OfferScreen(),
          ProfileScreen.routeName: (context) => ProfileScreen(),
          MoreScreen.routeName: (context) => MoreScreen(),
          DessertScreen.routeName: (context) => const DessertScreen(),
          IndividualItem.routeName: (context) => const IndividualItem(),
          PaymentScreen.routeName: (context) => const PaymentScreen(),
          NotificationScreen.routeName: (context) => NotificationScreen(),
          AboutScreen.routeName: (context) => AboutScreen(),
          InboxScreen.routeName: (context) => InboxScreen(),
          MyOrderScreen.routeName: (context) => const MyOrderScreen(),
          CheckoutScreen.routeName: (context) => const CheckoutScreen(),
          ChangeAddressScreen.routeName: (context) => const ChangeAddressScreen(),
          OrderTrackingScreen.routeName: (context) => const OrderTrackingScreen(),
          ShopperDashboardScreen.routeName: (context) => const ShopperDashboardScreen(),
          ShopManagementScreen.routeName: (context) => const ShopManagementScreen(),
          AdminDashboardScreen.routeName: (context) => const AdminDashboardScreen(),
          ShopsListScreen.routeName: (context) => const ShopsListScreen(),
          ShopProductsScreen.routeName: (context) => const ShopProductsScreen(),
          MyOrdersScreen.routeName: (context) => const MyOrdersScreen()
        },
      ),
    );
  }
}
