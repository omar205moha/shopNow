import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shop_now_mobile/screens/login_screen.dart';
import 'package:shop_now_mobile/utils/dialogs.dart';

class ProfileScreenController extends GetxController {
  final user = FirebaseAuth.instance.currentUser!;

  //sign user out function
  void signOut() {
    //sign user out
    AppDialogs.showConfirmDialog(
      messageText: 'Are you sure you want to sign out ?',
      onYesTap: () async {
        await FirebaseAuth.instance.signOut();
        await GetStorage().erase();
        Get.offAllNamed(LoginScreen.routeName);
      },
      yesButtonText: 'Yes',
      noButtonText: 'No',
    );
  }
}
