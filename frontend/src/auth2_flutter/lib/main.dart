import 'package:auth2_flutter/features/chat/presentation/pages/chat_page.dart';
import 'package:auth2_flutter/features/devices/devices.dart';
import 'package:auth2_flutter/features/patient/patient_search.dart';
import 'package:auth2_flutter/features/report/presentation/pages/report_page.dart';
import 'package:auth2_flutter/features/settings/pages/presentation/components/tile_pages/personal_info.dart';
import 'package:auth2_flutter/features/settings/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'features/data/domain/presentation/components/loading.dart';
import 'features/data/domain/presentation/cubits/auth_cubit.dart';
import 'features/data/domain/presentation/cubits/auth_states.dart';
import 'features/data/domain/presentation/pages/auth_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'package:auth2_flutter/themes/main_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/data/domain/presentation/repos/backend_auth_repo_impl.dart';

ThemeData mainTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF2F7D63),
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
  ),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF2F7D63),
    onPrimary: Colors.white,
    surface: Color(0xFF121212),
    onSurface: Colors.white,
  ),
);

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

//dark light mode 
  final ValueNotifier<ThemeMode> themeNotifier =
    ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  //auth repo
  final authRepo = BackendAuthRepoImpl();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      //provide cubits to app
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],

      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
          create: (context) =>
              AuthCubit(authRepo: authRepo)..checkAuth(),
        ),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        routes:{
          '/homepage':(context)=> HomePage(),
          '/settingspage':(context)=> SettingsPage(),
          '/reportpage':(context)=> ReportPage(),
          '/chatpage':(context)=> ChatPage(),
          '/patientpage':(context)=> PatientSearch(),
          '/devicepage':(context)=> DevicesPage(),
          '/personalinfopage':(context)=> PersonalInfo(),
        },

        //bloc consumer - auth
        home: DevicesPage(),
        /*BlocConsumer<AuthCubit, AuthState>(
          builder: (context, state) {
            print(state);
            //unathenticated -> auth page (login/register)
            if (state is Unauthenticated) {
              return const AuthPage();
            }

            //authenticated -> home page
            if (state is Authenticated) {
              return const HomePage();
            }
            //loading
            else {
              return LoadingScreen();
            }
          },
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text((state.message))));
            }
          },
        ), */
      theme: mainTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system
      
      ),
    );
  
  }
}
