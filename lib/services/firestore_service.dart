import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================= STATIONS =================

  /// Ambil semua stasiun
  Stream<List<Map<String, dynamic>>> getStationsStream() {
    return _db.collection('stations').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Ambil semua stasiun dengan jumlah sepeda tersedia (dari docks + bikes)
  Stream<List<Map<String, dynamic>>> getStationsWithBikeCountStream() {
    // Use a StreamController to combine multiple Firestore streams
    final controller = StreamController<List<Map<String, dynamic>>>();
    
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? lastStations;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? lastDocks;
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? lastBikes;
    
    void recalculate() {
      if (lastStations == null) return;
      
      final Map<String, int> availableBikesPerStation = {};
      final Map<String, int> totalDocksPerStation = {};
      
      // Count from docks
      if (lastDocks != null) {
        for (final dockDoc in lastDocks!) {
          final dockData = dockDoc.data();
          final stationId = dockData['stationId'] as String? ?? '';
          totalDocksPerStation[stationId] = (totalDocksPerStation[stationId] ?? 0) + 1;
          if (dockData['status'] == 'occupied') {
            availableBikesPerStation[stationId] = (availableBikesPerStation[stationId] ?? 0) + 1;
          }
        }
      }
      
      // Count from bikes collection
      if (lastBikes != null) {
        for (final bikeDoc in lastBikes!) {
          final bikeData = bikeDoc.data();
          if (bikeData['status'] == 'available') {
            final stationId = bikeData['currentStationId'] as String? ?? '';
            if (stationId.isNotEmpty) {
              availableBikesPerStation[stationId] = (availableBikesPerStation[stationId] ?? 0) + 1;
            }
          }
        }
      }
      
      final result = lastStations!.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        data['availableBikes'] = availableBikesPerStation[doc.id] ?? 0;
        data['totalDocks'] = totalDocksPerStation[doc.id] ?? 0;
        return data;
      }).toList();
      
      controller.add(result);
    }
    
    final sub1 = _db.collection('stations').snapshots().listen((snap) {
      lastStations = snap.docs;
      recalculate();
    });
    final sub2 = _db.collection('docks').snapshots().listen((snap) {
      lastDocks = snap.docs;
      recalculate();
    });
    final sub3 = _db.collection('bikes').snapshots().listen((snap) {
      lastBikes = snap.docs;
      recalculate();
    });
    
    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      sub3.cancel();
      controller.close();
    };
    
    return controller.stream;
  }


  /// Ambil detail satu stasiun berdasarkan nama (karena QR saat ini pakai nama)
  Future<Map<String, dynamic>?> getStationByName(String stationName) async {
    final query = await _db
        .collection('stations')
        .where('name', isEqualTo: stationName)
        .limit(1)
        .get();
    
    if (query.docs.isEmpty) return null;
    final data = query.docs.first.data();
    data['id'] = query.docs.first.id;
    return data;
  }

  // ================= DOCKS =================

  /// Ambil semua stasiun beserta jumlah dock tersedia
  Future<List<Map<String, dynamic>>> getStationsWithDockInfo(String excludeStationId) async {
    final stationsSnapshot = await _db.collection('stations').get();
    
    List<Map<String, dynamic>> result = [];
    for (final doc in stationsSnapshot.docs) {
      if (doc.id == excludeStationId) continue;
      
      final data = doc.data();
      data['id'] = doc.id;
      
      // Ambil docks
      final docksSnapshot = await _db.collection('docks').where('stationId', isEqualTo: doc.id).get();
      final totalDocks = docksSnapshot.docs.length;
      final availableDocks = docksSnapshot.docs.where((d) => d.data()['status'] == 'available').length;
      
      data['totalDocksCount'] = totalDocks;
      data['availableDocksCount'] = availableDocks;
      
      result.add(data);
    }
    return result;
  }

  /// Ambil semua dock untuk stasiun tertentu, diurutkan berdasarkan `order`
  Stream<List<Map<String, dynamic>>> getDocksStreamForStation(String stationId) {
    return _db
        .collection('docks')
        .where('stationId', isEqualTo: stationId)
        .snapshots()
        .map((snapshot) {
      final docsList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      docsList.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
      return docsList;
    });
  }

  /// Ambil detail satu dock berdasarkan stationId dan dockCode
  Future<Map<String, dynamic>?> getDockByCode(String stationId, String dockCode) async {
    final query = await _db
        .collection('docks')
        .where('stationId', isEqualTo: stationId)
        .get();
        
    for (final doc in query.docs) {
      final code = doc.data()['dockCode']?.toString() ?? doc.data()['number']?.toString() ?? '';
      if (code.toUpperCase() == dockCode.toUpperCase() || 
          code.toUpperCase() == 'D${dockCode.toUpperCase()}') {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }
    }
    return null;
  }

  // ================= TRIPS & BIKES =================

  /// Cek apakah user punya trip aktif
  Stream<Map<String, dynamic>?> getActiveTripStream(String userId) {
    return _db
        .collection('trips')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return data;
    });
  }

  /// Ambil riwayat trip user (selesai/batal)
  Stream<List<Map<String, dynamic>>> getTripHistoryStream(String userId) {
    return _db
        .collection('trips')
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['status'] != 'active')
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Ambil seluruh data sepeda (Bikes)
  Stream<List<Map<String, dynamic>>> getBikesStream() {
    return _db.collection('bikes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Update status manual sepeda (untuk halaman Manajemen Sepeda)
  Future<void> updateBikeStatus(String bikeId, String newStatus) async {
    await _db.collection('bikes').doc(bikeId).update({
      'status': newStatus,
    });
  }

  /// Ambil sepeda dari stasiun (Redistribusi / Evakuasi)
  Future<void> pickUpBike({
    required String dockId,
    required String bikeCode,
  }) async {
    final dockRef = _db.collection('docks').doc(dockId);
    final bikeRef = _db.collection('bikes').doc(bikeCode);

    final user = FirebaseAuth.instance.currentUser;
    final officerName = user?.displayName ?? user?.email ?? 'Unknown';

    await _db.runTransaction((transaction) async {
      transaction.update(dockRef, {
        'status': 'available',
        'currentBikeCode': null,
      });

      transaction.update(bikeRef, {
        'status': 'in_transit',
        'currentStationId': null,
        'currentDockId': null,
        'officerId': user?.uid,
        'officerName': officerName,
      });
    });
  }

  /// Taruh sepeda ke stasiun (Redistribusi)
  Future<void> dropOffBike({
    required String dockId,
    required String bikeCode,
    required String stationId,
  }) async {
    final dockRef = _db.collection('docks').doc(dockId);
    final bikeRef = _db.collection('bikes').doc(bikeCode);

    await _db.runTransaction((transaction) async {
      final bikeSnapshot = await transaction.get(bikeRef);
      if (!bikeSnapshot.exists) {
        throw Exception("Sepeda dengan kode $bikeCode tidak ditemukan di sistem!");
      }

      // Pastikan status dock di update ke filled/occupied dengan bike id ini
      transaction.update(dockRef, {
        'status': 'occupied',
        'currentBikeCode': bikeCode,
      });

      transaction.update(bikeRef, {
        'status': 'available',
        'currentStationId': stationId,
        'currentDockId': dockId,
        'officerId': FieldValue.delete(),
        'officerName': FieldValue.delete(),
      });
    });
  }

  /// Mulai pinjam sepeda (Atomic Update)
  Future<String> startTrip({
    required String userId,
    required String bikeCode,
    required String originStationId,
    required String originStationName,
    required String originDockId,
    required String destinationStationId,
    required String destinationStationName,
  }) async {
    final dockRef = _db.collection('docks').doc(originDockId);
    final bikeRef = _db.collection('bikes').doc(bikeCode);
    final tripRef = _db.collection('trips').doc(); // Auto-ID

    await _db.runTransaction((transaction) async {
      // 1. Buat trip
      transaction.set(tripRef, {
        'userId': userId,
        'bikeCode': bikeCode,
        'originStationId': originStationId,
        'originStationName': originStationName,
        'originDockId': originDockId,
        'destinationStationId': destinationStationId,
        'destinationStationName': destinationStationName,
        'destinationDockId': null,
        'status': 'active',
        'startedAt': FieldValue.serverTimestamp(),
        'completedAt': null,
        'durationMinutes': null,
      });

      // 2. Kosongkan dock (sepeda diambil)
      transaction.update(dockRef, {
        'status': 'available',
        'currentBikeCode': null,
      });

      // 3. Update status sepeda
      transaction.update(bikeRef, {
        'status': 'in_use',
        'currentDockId': null,
      });
    });

    return tripRef.id;
  }

  /// Kembalikan sepeda (Atomic Update)
  Future<void> completeTrip({
    required String tripId,
    required String returnStationId,
    required String returnStationName,
    required String returnDockId,
    required String bikeCode,
  }) async {
    final tripRef = _db.collection('trips').doc(tripId);
    final dockRef = _db.collection('docks').doc(returnDockId);
    final bikeRef = _db.collection('bikes').doc(bikeCode);

    await _db.runTransaction((transaction) async {
      final tripSnapshot = await transaction.get(tripRef);
      if (!tripSnapshot.exists) throw Exception("Trip tidak ditemukan!");

      final data = tripSnapshot.data();
      final startTime = (data?['startedAt'] as Timestamp?)?.toDate();
      String finalStatus = 'completed';

      if (startTime != null) {
        final durationInMinutes = DateTime.now().difference(startTime).inMinutes;
        // Jika dikembalikan dalam waktu <= 1 menit di stasiun yang sama, anggap dibatalkan
        if (durationInMinutes <= 1 && data?['originStationId'] == returnStationId) {
          finalStatus = 'cancelled';
        }
      }

      // 1. Update Trip
      transaction.update(tripRef, {
        'status': finalStatus,
        'completedAt': FieldValue.serverTimestamp(),
        'destinationDockId': returnDockId,
        'actualReturnStationId': returnStationId,
        'actualReturnStationName': returnStationName,
      });

      // 2. Update Dock (jadi terisi)
      transaction.update(dockRef, {
        'status': 'occupied',
        'currentBikeCode': bikeCode,
      });

      // 3. Update Bike
      transaction.update(bikeRef, {
        'status': 'available',
        'currentDockId': returnDockId,
      });
    });
  }

  // ================= TASKS =================

  /// Ambil tugas untuk officer tertentu
  Stream<List<Map<String, dynamic>>> getTasksForOfficer(String officerId) {
    return _db
        .collection('tasks')
        .where('assignedTo', isEqualTo: officerId)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Urutkan secara lokal untuk menghindari error Missing Index di Firestore
      tasks.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        // descending
        return bTime.compareTo(aTime);
      });
      
      return tasks;
    });
  }

  /// Update status tugas
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= OFFICERS =================

  /// Update lokasi petugas secara real-time
  Future<void> updateOfficerLocation(String officerId, String name, double lat, double lng) async {
    await _db.collection('officers').doc(officerId).set({
      'name': name,
      'lat': lat,
      'lng': lng,
      'lastUpdated': FieldValue.serverTimestamp(),
      'status': 'Online',
    }, SetOptions(merge: true));
  }

  /// Ambil profil petugas (berisi shift, dll)
  Stream<Map<String, dynamic>?> getOfficerProfileStream(String officerId) {
    return _db.collection('officers').doc(officerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    });
  }

  /// Ambil jadwal shift mingguan petugas
  Stream<List<Map<String, dynamic>>> getOfficerShiftsStream(String officerId) {
    return _db
        .collection('officers')
        .doc(officerId)
        .collection('shifts')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Hitung statistik performa petugas (Tasks Completed, Bikes Relocated)
  Stream<Map<String, int>> getOfficerStatsStream(String officerId) {
    return _db
        .collection('tasks')
        .where('assignedTo', isEqualTo: officerId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
      final completedTasks = snapshot.docs.length;
      
      // Bikes relocated calculation: 
      // For now, let's say every 'relocate_bike' task contributes to 1 bike relocated.
      // If we don't have task types, we'll just say every task completes relocates 2.5 bikes on average (just as a mock metric, or count specific types)
      int bikesRelocated = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'relocate_bike') {
          bikesRelocated += (data['bikeCount'] as int?) ?? 1;
        } else {
          // If no specific type, fallback to 1 per task
          bikesRelocated += 1;
        }
      }

      return {
        'tasksCompleted': completedTasks,
        'bikesRelocated': bikesRelocated,
      };
    });
  }

  // ================= MAINTENANCE =================

  /// Tandai barang (sepeda/dok) sebagai rusak
  Future<void> markItemAsBroken(Map<String, String> parsedData) async {
    if (parsedData.containsKey('bikeCode')) {
      // It's a bike
      final bikeCode = parsedData['bikeCode']!;
      await _db.collection('bikes').doc(bikeCode).update({
        'status': 'broken',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // It's a dock
      final stationName = parsedData['stationName'];
      final dockCode = parsedData['dockCode'];
      
      if (stationName == null || dockCode == null) {
        throw Exception("Data QR tidak valid untuk menandai dok.");
      }
      
      final station = await getStationByName(stationName);
      if (station == null) throw Exception("Stasiun tidak ditemukan.");
      
      final dock = await getDockByCode(station['id'], dockCode);
      if (dock == null) throw Exception("Dok tidak ditemukan di stasiun ini.");
      
      await _db.collection('docks').doc(dock['id']).update({
        'status': 'broken',
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ================= CHAT SUPPORT =================

  /// Ambil pesan obrolan antara officer tertentu dan admin
  Stream<List<Map<String, dynamic>>> getChatMessagesStream(String officerId) {
    return _db
        .collection('support_chats')
        .where('officerId', isEqualTo: officerId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort locally to avoid composite index requirement
      docs.sort((a, b) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final aTime = a['timestamp'] != null ? a['timestamp'].toDate().millisecondsSinceEpoch : now;
        final bTime = b['timestamp'] != null ? b['timestamp'].toDate().millisecondsSinceEpoch : now;
        return bTime.compareTo(aTime); // descending
      });
      
      return docs;
    });
  }

  /// Kirim pesan baru ke admin
  Future<void> sendMessage(String officerId, String message, {String senderRole = 'officer'}) async {
    await _db.collection('support_chats').add({
      'officerId': officerId,
      'senderId': officerId,
      'senderRole': senderRole,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // Update last message timestamp in officers collection for the dashboard to sort
    await _db.collection('officers').doc(officerId).set({
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessage': message,
      'hasUnreadAdmin': senderRole == 'officer',
      'hasUnreadOfficer': false, // Officer just sent, so they've seen the chat
    }, SetOptions(merge: true));
  }

  /// Mark chat as read for the officer (clear notification badge)
  Future<void> markChatAsReadForOfficer(String officerId) async {
    await _db.collection('officers').doc(officerId).set({
      'hasUnreadOfficer': false,
    }, SetOptions(merge: true));
  }

  // ================= SHIFTS & PRESENCE =================

  Future<void> checkInShift(String officerId, String shiftId, GeoPoint location) async {
    await _db
        .collection('officers')
        .doc(officerId)
        .collection('shifts')
        .doc(shiftId)
        .update({
      'isCheckedIn': true,
      'checkInTime': FieldValue.serverTimestamp(),
      'checkInLocation': location,
    });
  }

  Future<void> checkOutShift(String officerId, String shiftId) async {
    await _db
        .collection('officers')
        .doc(officerId)
        .collection('shifts')
        .doc(shiftId)
        .update({
      'checkOutTime': FieldValue.serverTimestamp(),
    });
  }

  Future<void> requestShiftSwap(String officerId, String shiftId, String reason, String requestedShift) async {
    await _db.collection('shift_requests').add({
      'officerId': officerId,
      'shiftId': shiftId,
      'reason': reason,
      'requestedShift': requestedShift,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    await _db
        .collection('officers')
        .doc(officerId)
        .collection('shifts')
        .doc(shiftId)
        .update({
      'swapStatus': 'pending',
    });
  }

  Future<void> generateInitialShifts(String officerId, String currentShift) async {
    final shifts = ['Shift Pagi', 'Shift Siang', 'Shift Malam', 'Libur'];
    int startIndex = shifts.indexWhere((s) => s.toLowerCase() == currentShift.toLowerCase());
    if (startIndex == -1) startIndex = 0;

    final batch = _db.batch();
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    for (int i = 0; i < 14; i++) {
      final date = todayStart.add(Duration(days: i));
      final shiftName = shifts[(startIndex + i) % shifts.length];
      
      final shiftRef = _db.collection('officers').doc(officerId).collection('shifts').doc();
      batch.set(shiftRef, {
        'date': Timestamp.fromDate(date),
        'shiftName': shiftName,
        'isCheckedIn': false,
        'checkInTime': null,
        'checkOutTime': null,
        'swapStatus': null,
      });
    }
    
    await batch.commit();
  }

  /// Stream to listen to officer's unread status
  Stream<bool> getUnreadStatusStream(String officerId) {
    return _db.collection('officers').doc(officerId).snapshots().map((doc) {
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['hasUnreadOfficer'] == true;
    });
  }
}
