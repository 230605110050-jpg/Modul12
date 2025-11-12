import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Untuk font Poppins
import 'package:geolocator/geolocator.dart'; // Untuk mendapatkan koordinat GPS
import 'package:geocoding/geocoding.dart'; // Untuk reverse geocoding

// Pastikan Anda telah menambahkan package-package di atas ke pubspec.yaml

void main() {
  runApp(const MyApp());
}

// Bagian (g): Kelas MyApp menggunakan MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lokasi Saya',
      theme: ThemeData(
        // Menggunakan primary color indigo
        primarySwatch: Colors.indigo,
        // Menggunakan Google Fonts Poppins
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      // Menjadikan LocationScreen sebagai halaman utama
      home: const GeolocationScreen(),
    );
  }
}

// ---

// Bagian (g): Kelas LocationScreen (diubah namanya menjadi GeolocationScreen)
class GeolocationScreen extends StatefulWidget {
  const GeolocationScreen({super.key});

  @override
  State<GeolocationScreen> createState() => _GeolocationScreenState();
}

class _GeolocationScreenState extends State<GeolocationScreen> {
  // Variabel untuk menyimpan data lokasi, status loading, dan pesan error
  String? _kecamatan;
  String? _kota;
  bool _isLoading = false;
  String? _errorMessage;

  // ---

  // Bagian (h): Fungsi _getLocation() untuk mengambil dan memproses lokasi
  Future<void> _getLocation() async {
    // 1. Set status loading dan reset data
    setState(() {
      _isLoading = true; // Menandai aplikasi sedang memproses lokasi
      _errorMessage = null; // Menghapus pesan error sebelumnya
      _kecamatan = null; // Menghapus data kecamatan sebelumnya
      _kota = null; // Menghapus data kota sebelumnya
    });

    try {
      // 2. Cek apakah layanan lokasi (GPS) aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif. Mohon aktifkan GPS.');
      }

      // 3. Periksa izin akses lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak oleh pengguna.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Izin lokasi ditolak permanen. Anda harus mengubahnya di pengaturan aplikasi.',
        );
      }

      // 4. Ambil posisi perangkat saat ini
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ); // Presisi tinggi

      // 5. Lakukan reverse geocoding untuk mengubah koordinat menjadi alamat
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _kecamatan = place.subLocality ?? place.locality ?? 'Tidak diketahui';
          _kota = place.locality ?? place.subAdministrativeArea ?? 'Tidak diketahui';
        });
      } else {
        throw Exception('Tidak dapat menemukan informasi alamat.');
      }
    } catch (e) {
      // 6. Tangani error dan tampilkan pesan
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      // 7. Hentikan status loading
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ---

  // Bagian (i): Implementasi method build() dengan UI responsif
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Saya', style: TextStyle(color: Colors.white)),
        // Warna biru gelap untuk AppBar
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card untuk menampilkan informasi lokasi atau status
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32.0,
                  horizontal: 10.0,
                ),
                child: _isLoading
                    // Kondisi 1: Jika sedang loading, tampilkan CircularProgressIndicator
                    ? const Center(child: CircularProgressIndicator())
                    // Kondisi 2: Jika ada error, tampilkan pesan error
                    : (_errorMessage != null)
                    ? Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      )
                    // Kondisi 3: Jika belum ada data dan tidak ada error, tampilkan placeholder
                    : (_kecamatan == null && _kota == null)
                    ? const Text(
                        'Tekan tombol untuk menampilkan lokasi.',
                        textAlign: TextAlign.center,
                      )
                    // Kondisi 4: Data lokasi berhasil didapatkan
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelurahan/Kecamatan: $_kecamatan',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Kota: $_kota',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),
            // Tombol untuk memanggil fungsi _getLocation
            ElevatedButton(
              // Tombol dinonaktifkan saat _isLoading true
              onPressed: _isLoading ? null : _getLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 5.0,
              ),
              child: const Text(
                'TAMPILKAN LOKASI SAAT INI',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
