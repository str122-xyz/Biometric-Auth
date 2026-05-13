import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Beranda',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 100,
              color: Colors.teal,
            ),
            const SizedBox(height: 24),
            const Text(
              'Login Berhasil!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Selamat datang di aplikasi\nBiometric Auth Demo',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
