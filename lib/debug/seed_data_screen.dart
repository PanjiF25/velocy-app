import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});

  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  bool _isLoading = false;
  String _status = '';

  Future<void> _seedDatabase() async {
    setState(() {
      _isLoading = true;
      _status = 'Memulai proses seeding...';
    });

    final db = FirebaseFirestore.instance;

    try {
      // 1. Tambah Stations
      setState(() => _status = 'Menambahkan stasiun...');
      final station1Id = 'station_ti';
      await db.collection('stations').doc(station1Id).set({
        'name': 'Stasiun Gedung Teknik Informatika',
        'address': 'Gedung Teknik Informatika ITS, Sukolilo, Surabaya',
        'latitude': -7.2817,
        'longitude': 112.7961,
        'totalDocks': 6,
      });

      final station2Id = 'station_perpustakaan';
      await db.collection('stations').doc(station2Id).set({
        'name': 'Stasiun Perpustakaan Pusat ITS',
        'address': 'Perpustakaan Pusat ITS, Sukolilo, Surabaya',
        'latitude': -7.2777,
        'longitude': 112.7944,
        'totalDocks': 6,
      });

      final station3Id = 'station_arsitektur';
      await db.collection('stations').doc(station3Id).set({
        'name': 'Stasiun Departemen Arsitektur',
        'address': 'Departemen Arsitektur ITS, Sukolilo, Surabaya',
        'latitude': -7.2829,
        'longitude': 112.7933,
        'totalDocks': 6,
      });

      // 2. Tambah Bikes
      setState(() => _status = 'Menambahkan sepeda...');
      final bikes = ['VLY-001', 'VLY-002', 'VLY-003', 'VLY-004', 'VLY-005'];
      for (final bikeCode in bikes) {
        await db.collection('bikes').doc(bikeCode).set({
          'status': 'available', // available, in_use, maintenance
          'currentDockId': null, // Di-update setelah dock diassign
        });
      }

      // 3. Tambah Docks
      setState(() => _status = 'Menambahkan dock...');
      
      Future<void> createDocks(String stationId, String prefix, List<String> initialBikes) async {
        for (int i = 1; i <= 6; i++) {
          final dockId = '$prefix$i';
          final bikeCode = (i <= initialBikes.length) ? initialBikes[i - 1] : null;
          
          await db.collection('docks').doc(dockId).set({
            'stationId': stationId,
            'label': 'Dok $i',
            'status': bikeCode != null ? 'occupied' : 'available',
            'currentBikeCode': bikeCode,
            'order': i,
            'sensorPin': i - 1,
            'actuatorPin': i - 1,
            'dockCode': 'D$i',
          });

          if (bikeCode != null) {
            await db.collection('bikes').doc(bikeCode).update({
              'currentDockId': dockId,
            });
          }
        }
      }

      await createDocks(station1Id, 'A', ['VLY-001', 'VLY-002']);
      await createDocks(station2Id, 'B', ['VLY-003']);
      await createDocks(station3Id, 'C', ['VLY-004', 'VLY-005']);

      setState(() => _status = 'Seeding berhasil!');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Database')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Gunakan ini HANYA SEKALI untuk mengisi data dummy ke Firestore.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _seedDatabase,
                child: const Text('Jalankan Seeder'),
              ),
              const SizedBox(height: 24),
              if (_isLoading) const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
