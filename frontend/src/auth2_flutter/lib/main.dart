import 'package:auth2_flutter/features/chat/presentation/pages/chat_page.dart';
import 'package:auth2_flutter/features/devices/devices.dart';
import 'package:auth2_flutter/features/patient/patient_search.dart';
import 'package:auth2_flutter/features/report/presentation/pages/report_page.dart';
import 'package:auth2_flutter/features/settings/pages/settings_page.dart';

import 'features/data/domain/presentation/components/loading.dart';
import 'features/data/domain/presentation/cubits/auth_cubit.dart';
import 'features/data/domain/presentation/cubits/auth_states.dart';
import 'features/data/domain/presentation/pages/auth_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'themes/main_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/data/domain/presentation/repos/backend_auth_repo_impl.dart';

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
    return MultiBlocProvider(
      //provide cubits to app
      providers: [
        //auth cubit
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
        },

        //bloc consumer - auth
        home: DevicesPage()
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
        //theme: mainTheme,
      
      
      ),
    );
  
  }
}
