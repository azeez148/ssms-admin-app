import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkApiHealth();
  }

  Future<void> _checkApiHealth() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final isApiHealthy = await ApiService.instance.checkServerAvailability();
      if (isApiHealthy) {
        print('isApiHealthy: $isApiHealthy');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        print('isApiHealthy: $isApiHealthy');
        setState(() {
          _isLoading = false;
          _error = 'The API is not available. Please try again later.';
        });
      }
    } catch (e) {
      print('isApiHealthy: false');
      setState(() {
        _isLoading = false;
        _error = 'An error occurred: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error ?? 'An unknown error occurred.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkApiHealth,
                    child: const Text('Retry'),
                  ),
                ],
              ),
      ),
    );
  }
}
