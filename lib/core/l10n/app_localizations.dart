import 'package:flutter/material.dart';
import 'package:velocy_app/core/providers/settings_provider.dart';

class AppLocalizations {
  static bool get isIndo => SettingsProvider().locale.languageCode == 'id';

  // Translates a key by looking up the dictionary.
  // Fallback to English if not found.
  static String tr(String key) {
    if (isIndo) {
      return _idMap[key] ?? _enMap[key] ?? key;
    }
    return _enMap[key] ?? key;
  }

  static const Map<String, String> _enMap = {
    // General
    'Loading': 'Loading...',
    'Cancel': 'Cancel',
    'Confirm': 'Confirm',
    'Submit': 'Submit',
    'Error': 'Error',
    'Success': 'Success',
    'Back': 'Back',
    'Close': 'Close',

    // Login
    'LoginTitle': 'Ready to Ride?',
    'LoginSubtitle': 'Enter your student email to begin your journey across campus.',
    'EmailHint': 'student@univ.edu',
    'PasswordHint': 'Password',
    'ForgotPassword': 'Forgot Password?',
    'SignIn': 'Sign In',
    'CreatingAccount': 'Don\'t have an account?',
    'Register': 'Register',
    'InvalidCredentials': 'Invalid credentials. Try demo@velocy.com / password',
    'WelcomeBack': 'Welcome back!',

    // Home User
    'HomeGreeting': 'Hi, Panji!',
    'SearchDestination': 'Where to?',
    'NearYou': 'Near You',
    'ViewAll': 'View All',
    'BikesAvailable': 'bikes available',
    'Distance': 'Distance',
    'NavHome': 'Home',
    'NavRent': 'Rent',
    'NavTrip': 'Trip',
    'NavProfile': 'Profile',
    'LocationPermissionDenied': 'Location permissions are denied',
    'LocationPermissionPermanent': 'Location permissions are permanently denied, we cannot request permissions.',
    'MapError': 'Failed to load map data.',
    'TapToScan': 'Tap to Scan QR',

    // Rent & Scanner
    'UnlockBike': 'Unlock a Bike',
    'ScanQRToUnlock': 'Scan the QR code on the bike to unlock it.',
    'EnterBikeID': 'Or enter Bike ID manually',
    'BikeID': 'Bike ID',
    'Unlock': 'Unlock',
    'Scanning': 'Scanning...',
    'AlignQR': 'Align QR code within the frame',
    'UnlockingBike': 'Unlocking bike...',
    'BikeUnlocked': 'Bike unlocked successfully!',
    'InvalidQR': 'Invalid QR code. Please try again.',
    'ProvideBikeID': 'Please provide a valid Bike ID',

    // Trip
    'ActiveTrip': 'Active Trip',
    'TripDuration': 'Duration',
    'TripDistance': 'Distance',
    'TripCalories': 'Calories',
    'ReturnBike': 'Return Bike',
    'ReportIssue': 'Report Issue',
    'NoActiveTrip': 'No active trip',
    'StartTripToSee': 'Start a trip to see your stats here.',
    'TripStats': 'Trip Stats',

    // Station Detail
    'StationDetail': 'Station Detail',
    'AvailableBikes': 'Available Bikes',
    'AvailableDocks': 'Available Docks',
    'GetDirections': 'Get Directions',
    'StationFull': 'Station Full',
    'StationEmpty': 'Station Empty',

    // Return Bike
    'ReturningBike': 'Returning Bike',
    'ScanDockQR': 'Scan Dock QR',
    'ScanDockInstruction': 'Scan the QR code on the dock to return your bike.',
    'ProcessingReturn': 'Processing return...',
    'ReturnSuccess': 'Bike returned successfully!',
    'DockID': 'Dock ID',

    // Loan Summary
    'TripSummary': 'Trip Summary',
    'TotalTime': 'Total Time',
    'TotalCost': 'Total Cost',
    'Free': 'Free',
    'CarbonSaved': 'Carbon Saved',
    'Done': 'Done',

    // Report Issue
    'ReportProblem': 'Report Problem',
    'DescribeIssue': 'Describe the issue...',
    'SubmitReport': 'Submit Report',
    'IssueReported': 'Issue reported. Thank you!',
    'CategoryMechanical': 'Mechanical',
    'CategorySoftware': 'Software',
    'CategoryOther': 'Other',
    'SelectCategory': 'Select Category',
    'PhotoOptional': 'Attach Photo (Optional)',

    // Profile User
    'MyProfile': 'My Profile',
    'EditProfile': 'Edit Profile',
    'TripHistory': 'Trip History',
    'PaymentMethods': 'Payment Methods',
    'HelpSupport': 'Help & Support',
    'LogOut': 'Log Out',
    'AreYouSureLogout': 'Are you sure you want to log out?',

    // Officer App - Home
    'OfficerHome': 'Officer Dashboard',
    'Overview': 'Overview',
    'ActiveTasks': 'Active Tasks',
    'BikesNeedingAttention': 'Bikes Needing Attention',
    'LowBatteryBikes': 'Low Battery Bikes',
    'RecentAlerts': 'Recent Alerts',

    // Officer App - Tasks
    'Tasks': 'Tasks',
    'AllTasks': 'All',
    'PendingTasks': 'Pending',
    'InProgressTasks': 'In Progress',
    'CompletedTasks': 'Completed',
    'TaskDetail': 'Task Detail',
    'MarkAsCompleted': 'Mark as Completed',
    'MarkAsInProgress': 'Start Task',
    'TaskAssignedToYou': 'Assigned to you',

    // Officer App - Bikes
    'ManageBikes': 'Manage Bikes',
    'SearchBikes': 'Search bike ID...',
    'FilterStatus': 'Status',
    'StatusAvailable': 'Available',
    'StatusInUse': 'In Use',
    'StatusMaintenance': 'Maintenance',
    'MarkBroken': 'Mark Broken',
    'MarkFixed': 'Mark Fixed',
    'BikeDetails': 'Bike Details',
    'BatteryLevel': 'Battery Level',
    'LastMaintained': 'Last Maintained',

    // Officer App - Scanner
    'OfficerScanner': 'Officer Scanner',
    'ScanToManage': 'Scan a bike or dock QR to manage it.',
    'ProcessAction': 'Process Action',

    // Officer App - Profile
    'OfficerProfile': 'Officer Profile',
    'ShiftSchedule': 'Shift Schedule',
    'AdminSupport': 'Contact Admin Support',
    'AppSettings': 'App Settings',
    'Performance': 'Performance',
    'TasksCompleted': 'Tasks Completed\nThis Week',
    'ResponseTime': 'Avg Response\nTime',
    'Management': 'MANAGEMENT',
    'MorningShift': 'Morning Shift',

    // Settings
    'Settings': 'Settings',
    'Appearance': 'APPEARANCE',
    'Localization': 'LOCALIZATION',
    'Notifications': 'NOTIFICATIONS',
    'About': 'ABOUT',
    'Theme': 'Theme',
    'Light': 'Light',
    'Dark': 'Dark',
    'System': 'System',
    'Language': 'Language',
    'PushNotifications': 'Push Notifications',
    'TaskAlerts': 'Task Alerts',
    'Version': 'Version',
    'TermsOfService': 'Terms of Service',
  };

  static const Map<String, String> _idMap = {
    // General
    'Loading': 'Memuat...',
    'Cancel': 'Batal',
    'Confirm': 'Konfirmasi',
    'Submit': 'Kirim',
    'Error': 'Kesalahan',
    'Success': 'Berhasil',
    'Back': 'Kembali',
    'Close': 'Tutup',

    // Login
    'LoginTitle': 'Siap Berkendara?',
    'LoginSubtitle': 'Masukkan email mahasiswa Anda untuk memulai perjalanan melintasi kampus.',
    'EmailHint': 'mahasiswa@univ.edu',
    'PasswordHint': 'Kata Sandi',
    'ForgotPassword': 'Lupa Kata Sandi?',
    'SignIn': 'Masuk',
    'CreatingAccount': 'Belum punya akun?',
    'Register': 'Daftar',
    'InvalidCredentials': 'Kredensial tidak valid. Coba demo@velocy.com / password',
    'WelcomeBack': 'Selamat datang kembali!',

    // Home User
    'HomeGreeting': 'Hai, Panji!',
    'SearchDestination': 'Mau kemana?',
    'NearYou': 'Di Dekat Anda',
    'ViewAll': 'Lihat Semua',
    'BikesAvailable': 'sepeda tersedia',
    'Distance': 'Jarak',
    'NavHome': 'Beranda',
    'NavRent': 'Sewa',
    'NavTrip': 'Perjalanan',
    'NavProfile': 'Profil',
    'LocationPermissionDenied': 'Izin lokasi ditolak',
    'LocationPermissionPermanent': 'Izin lokasi ditolak secara permanen, kami tidak dapat meminta izin.',
    'MapError': 'Gagal memuat data peta.',
    'TapToScan': 'Ketuk untuk Pindai QR',

    // Rent & Scanner
    'UnlockBike': 'Buka Kunci Sepeda',
    'ScanQRToUnlock': 'Pindai kode QR pada sepeda untuk membuka kuncinya.',
    'EnterBikeID': 'Atau masukkan ID Sepeda secara manual',
    'BikeID': 'ID Sepeda',
    'Unlock': 'Buka Kunci',
    'Scanning': 'Memindai...',
    'AlignQR': 'Posisikan kode QR di dalam bingkai',
    'UnlockingBike': 'Membuka kunci sepeda...',
    'BikeUnlocked': 'Sepeda berhasil dibuka!',
    'InvalidQR': 'Kode QR tidak valid. Silakan coba lagi.',
    'ProvideBikeID': 'Harap berikan ID Sepeda yang valid',

    // Trip
    'ActiveTrip': 'Perjalanan Aktif',
    'TripDuration': 'Durasi',
    'TripDistance': 'Jarak',
    'TripCalories': 'Kalori',
    'ReturnBike': 'Kembalikan Sepeda',
    'ReportIssue': 'Laporkan Masalah',
    'NoActiveTrip': 'Tidak ada perjalanan aktif',
    'StartTripToSee': 'Mulai perjalanan untuk melihat statistik Anda di sini.',
    'TripStats': 'Statistik Perjalanan',

    // Station Detail
    'StationDetail': 'Detail Stasiun',
    'AvailableBikes': 'Sepeda Tersedia',
    'AvailableDocks': 'Dermaga Tersedia',
    'GetDirections': 'Dapatkan Arah',
    'StationFull': 'Stasiun Penuh',
    'StationEmpty': 'Stasiun Kosong',

    // Return Bike
    'ReturningBike': 'Mengembalikan Sepeda',
    'ScanDockQR': 'Pindai QR Dermaga',
    'ScanDockInstruction': 'Pindai kode QR pada dermaga untuk mengembalikan sepeda Anda.',
    'ProcessingReturn': 'Memproses pengembalian...',
    'ReturnSuccess': 'Sepeda berhasil dikembalikan!',
    'DockID': 'ID Dermaga',

    // Loan Summary
    'TripSummary': 'Ringkasan Perjalanan',
    'TotalTime': 'Total Waktu',
    'TotalCost': 'Total Biaya',
    'Free': 'Gratis',
    'CarbonSaved': 'Karbon Dihemat',
    'Done': 'Selesai',

    // Report Issue
    'ReportProblem': 'Laporkan Masalah',
    'DescribeIssue': 'Jelaskan masalahnya...',
    'SubmitReport': 'Kirim Laporan',
    'IssueReported': 'Masalah dilaporkan. Terima kasih!',
    'CategoryMechanical': 'Mekanis',
    'CategorySoftware': 'Perangkat Lunak',
    'CategoryOther': 'Lainnya',
    'SelectCategory': 'Pilih Kategori',
    'PhotoOptional': 'Lampirkan Foto (Opsional)',

    // Profile User
    'MyProfile': 'Profil Saya',
    'EditProfile': 'Edit Profil',
    'TripHistory': 'Riwayat Perjalanan',
    'PaymentMethods': 'Metode Pembayaran',
    'HelpSupport': 'Bantuan & Dukungan',
    'LogOut': 'Keluar',
    'AreYouSureLogout': 'Apakah Anda yakin ingin keluar?',

    // Officer App - Home
    'OfficerHome': 'Dasbor Petugas',
    'Overview': 'Ringkasan',
    'ActiveTasks': 'Tugas Aktif',
    'BikesNeedingAttention': 'Sepeda Butuh Perhatian',
    'LowBatteryBikes': 'Sepeda Baterai Rendah',
    'RecentAlerts': 'Peringatan Terbaru',

    // Officer App - Tasks
    'Tasks': 'Tugas',
    'AllTasks': 'Semua',
    'PendingTasks': 'Tertunda',
    'InProgressTasks': 'Berlangsung',
    'CompletedTasks': 'Selesai',
    'TaskDetail': 'Detail Tugas',
    'MarkAsCompleted': 'Tandai Selesai',
    'MarkAsInProgress': 'Mulai Tugas',
    'TaskAssignedToYou': 'Ditugaskan kepada Anda',

    // Officer App - Bikes
    'ManageBikes': 'Manajemen Sepeda',
    'SearchBikes': 'Cari ID sepeda...',
    'FilterStatus': 'Status',
    'StatusAvailable': 'Tersedia',
    'StatusInUse': 'Digunakan',
    'StatusMaintenance': 'Perawatan',
    'MarkBroken': 'Tandai Rusak',
    'MarkFixed': 'Tandai Diperbaiki',
    'BikeDetails': 'Detail Sepeda',
    'BatteryLevel': 'Tingkat Baterai',
    'LastMaintained': 'Terakhir Dirawat',

    // Officer App - Scanner
    'OfficerScanner': 'Pemindai Petugas',
    'ScanToManage': 'Pindai QR sepeda atau dermaga untuk mengelolanya.',
    'ProcessAction': 'Proses Aksi',

    // Officer App - Profile
    'OfficerProfile': 'Profil Petugas',
    'ShiftSchedule': 'Jadwal Giliran',
    'AdminSupport': 'Hubungi Dukungan Admin',
    'AppSettings': 'Pengaturan Aplikasi',
    'Performance': 'Performa',
    'TasksCompleted': 'Tugas Selesai\nMinggu Ini',
    'ResponseTime': 'Rata-rata Waktu\nRespon',
    'Management': 'MANAJEMEN',
    'MorningShift': 'Giliran Pagi',

    // Settings
    'Settings': 'Pengaturan',
    'Appearance': 'TAMPILAN',
    'Localization': 'LOKALISASI',
    'Notifications': 'NOTIFIKASI',
    'About': 'TENTANG',
    'Theme': 'Tema',
    'Light': 'Terang',
    'Dark': 'Gelap',
    'System': 'Sistem',
    'Language': 'Bahasa',
    'PushNotifications': 'Notifikasi Push',
    'TaskAlerts': 'Peringatan Tugas',
    'Version': 'Versi',
    'TermsOfService': 'Syarat Layanan',
  };
}
