import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Hide status bar for full screen immersion
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const EpicGameApp());
}

class EpicGameApp extends StatelessWidget {
  const EpicGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Epic Space Defender',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.purpleAccent,
          surface: Colors.black,
        ),
        useMaterial3: true,
        fontFamily: 'Courier', // Monospaced font for retro feel
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const GameScreen(),
      },
    );
  }
}
