import 'package:auth2_flutter/features/chat/presentation/pages/chat_page.dart';
import 'package:auth2_flutter/features/report/presentation/pages/report_page.dart';
import 'package:auth2_flutter/features/settings/pages/settings_page.dart';

import 'features/data/domain/presentation/components/loading.dart';
import 'features/data/domain/presentation/cubits/auth_cubit.dart';
import 'features/data/domain/presentation/cubits/auth_states.dart';
import 'features/data/domain/presentation/cubits/pages/auth_page.dart';
import 'features/data/firebase_auth_repo.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'package:auth2_flutter/firebase_options.dart';
import 'themes/main_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  //auth repo
  final firebaseAuthRepo = FirebaseAuthRepo();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      //provide cubits to app
      providers: [
        //auth cubit
        BlocProvider<AuthCubit>(
          create: (context) =>
              AuthCubit(authRepo: firebaseAuthRepo)..checkAuth(),
        ),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        routes:{
          '/homepage':(context)=> HomePage(),
          '/settingspage':(context)=> SettingsPage(),
          '/reportpage':(context)=> ReportPage(),
          '/chatpage':(context)=> ChatPage(),
        },

        //bloc consumer - auth
        home: HomePage()
        
        /*
        BlocConsumer<AuthCubit, AuthState>(
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
        ),
        theme: mainTheme,
      
      
      */),
    );
  
  }
}
