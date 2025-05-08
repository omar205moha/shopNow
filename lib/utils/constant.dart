import 'package:get_storage/get_storage.dart';

enum PrefKey { userId, userEmail, userLastName, userFirstsname, userPhone, userAddress, userType }

String? get getUserType => GetStorage().read<String>(PrefKey.userType.name);
