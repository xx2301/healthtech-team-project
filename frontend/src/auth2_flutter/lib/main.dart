import 'package:auth2_flutter/features/chat/presentation/pages/chat_page.dart';
import 'package:auth2_flutter/features/devices/devices.dart';
import 'package:auth2_flutter/features/patient/patient_search.dart';
import 'package:auth2_flutter/features/report/presentation/pages/report_page.dart';
import 'package:auth2_flutter/features/settings/pages/presentation/components/tile_pages/personal_info.dart';
import 'package:auth2_flutter/features/settings/pages/settings_page.dart';
import 'features/data/domain/presentation/components/loading.dart';
import 'features/data/domain/presentation/cubits/auth_cubit.dart';
import 'features/data/domain/presentation/cubits/auth_states.dart';
import 'features/data/domain/presentation/pages/auth_page.dart';
import 'features/data/domain/presentation/pages/reset_password_page.dart';
import 'features/data/domain/presentation/pages/change_password_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'themes/main_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'features/data/domain/presentation/repos/backend_auth_repo_impl.dart';
import 'features/medical_record/presentation/pages/medical_records_page.dart';
import 'package:auth2_flutter/features/report/presentation/pages/metric_detail_page.dart';
import 'package:auth2_flutter/features/thresholds/pages/threshold_settings_page.dart';
import 'package:auth2_flutter/features/notifications/pages/notification_list_page.dart';
import 'package:auth2_flutter/features/goals/pages/goals_page.dart';
import 'package:auth2_flutter/features/doctor/pages/doctor_dashboard.dart';
import 'package:auth2_flutter/features/auth/pages/apply_doctor_page.dart';
import 'package:auth2_flutter/features/admin/admin_page.dart';
import 'package:auth2_flutter/features/admin/admin_review_application.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final authRepo = BackendAuthRepoImpl();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(authRepo: authRepo)..checkAuth(),
          ),
        ],
        child: Consumer<ThemeNotifier>(
          builder: (context, themeNotifier, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              routes: {
                '/homepage': (context) => HomePage(),
                '/settingspage': (context) => SettingsPage(),
                '/reportpage': (context) => ReportPage(),
                '/chatpage': (context) => ChatPage(),
                '/patientpage': (context) => PatientSearch(),
                '/devicepage': (context) => DevicesPage(),
                '/personalinfopage': (context) => PersonalInfo(),
                '/reset-password': (context) => const ResetPasswordPage(),
                '/change-password': (context) => const ChangePasswordPage(),
                '/medicalrecords': (context) => const MedicalRecordsPage(),
                '/metric-detail': (context) {
                  final args = ModalRoute.of(context)!.settings.arguments as Map;
                  return MetricDetailPage(
                    metricType: args['metricType'],
                    title: args['title'],
                  );
                },
                '/notifications': (context) => NotificationListPage(),
                '/thresholds': (context) => ThresholdSettingsPage(),
                '/goals': (context) => const GoalsPage(),
                '/doctor-dashboard': (context) => const DoctorDashboard(),
                '/apply-doctor': (context) => const ApplyDoctorPage(),
                '/admin': (context) => const AdminDashboard(),
                '/admin/review': (context) => const AdminReviewApplications(),  
              },
              theme: mainTheme,
              darkTheme: darkTheme,
              themeMode: themeNotifier.themeMode,
              home: 
              
              
              BlocConsumer<AuthCubit, AuthState>(
                builder: (context, state) {
                  print('AuthState in builder: $state');
                  if (state is Unauthenticated) {
                    return const AuthPage();
                  }
                  if (state is Authenticated) {
                    return const HomePage();
                  }
                  return const LoadingScreen();
                },
                listener: (context, state) {
                  if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  }

                  if (state is Unauthenticated) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    });
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}