import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smm_app/shared/widgets/update_dialog.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/client_calendar_provider.dart';
import 'core/providers/client_design_project_provider.dart';
import 'core/providers/gd_project_provider.dart';
import 'core/providers/social_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/smm/smm_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => GdProjectProvider()),
        ChangeNotifierProvider(
          create: (_) => SocialProvider(),
        ),
        ChangeNotifierProvider(create: (_) => ClientDesignProjectProvider()),
        ChangeNotifierProvider(create: (_) => ClientCalendarProvider()),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.createRouter(context);
          return MaterialApp.router(
            title: 'GrowthCraft SMM',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: router,
            builder: (context, child) => _UpdateWrapper(child: child ?? const SizedBox()),
          );
        },
      ),
    );
  }
}

/// App load hone ke baad update check karta hai
class _UpdateWrapper extends StatefulWidget {
  final Widget child;
  const _UpdateWrapper({required this.child});

  @override
  State<_UpdateWrapper> createState() => _UpdateWrapperState();
}

class _UpdateWrapperState extends State<_UpdateWrapper> {
  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    // 2 second baad check karo taaki splash/login smooth rahe
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final info = await UpdateService.checkForUpdate();
    if (!mounted || info == null) return;
    await UpdateDialog.show(context, info);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}