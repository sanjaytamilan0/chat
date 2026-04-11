import 'package:get/get.dart';
import '../presentation/shared/widgets/bottom_nav_bar.dart';
import '../presentation/auth/ui/login_screen.dart';
import '../presentation/auth/ui/register_screen.dart';
import '../presentation/splash/ui/splash_screen.dart';
import 'route_name.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.root,
      page: () => const GhostChatSplashScreen(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const BottomNavBar(),
    ),
  ];
}
