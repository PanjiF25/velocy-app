import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'navigation_helper.dart';
import 'station_detail_screen.dart';

class RentScreen extends StatefulWidget {
	const RentScreen({super.key});

	@override
	State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen> {
	final MobileScannerController _controller = MobileScannerController();
	bool _isScanning = true;
	bool _showResultSheet = false;
	String _scannedQrValue = '';

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final cutOutSize = MediaQuery.of(context).size.width * 0.64;

		return Scaffold(
			backgroundColor: const Color(0xFFF9F9FF),
			appBar: AppBar(
				backgroundColor: const Color(0xFFF9F9FF),
				elevation: 0,
				scrolledUnderElevation: 0,
				leading: IconButton(
					icon: const Icon(Icons.arrow_back, color: Color(0xFF3F4944)),
					onPressed: () => switchToTab(context, 0),
				),
				centerTitle: true,
				title: const Text(
					'Pindai QR',
					style: TextStyle(
						fontFamily: 'Inter',
						fontSize: 20,
						fontWeight: FontWeight.w700,
						color: Color(0xFF005440),
					),
				),
				actions: [
					IconButton(
						icon: const Icon(Icons.language, color: Color(0xFF3F4944)),
						onPressed: () {},
					),
				],
			),
			bottomNavigationBar: NavigationBar(
				selectedIndex: 1,
				onDestinationSelected: (index) {
					if (index == 1) {
						return;
					}

					switchToTab(context, index);
				},
				backgroundColor: Colors.white,
				indicatorColor: const Color(0xFF0F6E56),
				destinations: const [
					NavigationDestination(
						icon: Icon(Icons.home_outlined),
						selectedIcon: Icon(Icons.home, color: Colors.white),
						label: 'Home',
					),
					NavigationDestination(
						icon: Icon(Icons.qr_code_scanner),
						selectedIcon: Icon(Icons.qr_code_scanner, color: Colors.white),
						label: 'Rent',
					),
					NavigationDestination(
						icon: Icon(Icons.directions_bike),
						selectedIcon: Icon(Icons.directions_bike, color: Colors.white),
						label: 'Trip',
					),
					NavigationDestination(
						icon: Icon(Icons.person_outline),
						selectedIcon: Icon(Icons.person, color: Colors.white),
						label: 'Profile',
					),
				],
			),
			body: Stack(
				children: [
					Positioned.fill(
						child: MobileScanner(
							controller: _controller,
							onDetect: (capture) async {
								if (!_isScanning || _showResultSheet || capture.barcodes.isEmpty) return;

								final barcode = capture.barcodes.first;
								final value = barcode.rawValue ?? barcode.displayValue ?? '';
								if (value.isEmpty) return;

								setState(() {
									_scannedQrValue = value;
									_isScanning = false;
									_showResultSheet = true;
								});
								await _controller.stop();
							},
						),
					),
					SafeArea(
						child: Stack(
							children: [
								Column(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										const SizedBox(height: 12),
										SizedBox(
											width: cutOutSize,
											height: cutOutSize,
											child: Stack(
												children: [
													const Positioned(
														top: 0,
														left: 0,
														child: _CornerBracket(top: true, left: true),
													),
													const Positioned(
														top: 0,
														right: 0,
														child: _CornerBracket(top: true, left: false),
													),
													const Positioned(
														bottom: 0,
														left: 0,
														child: _CornerBracket(top: false, left: true),
													),
													const Positioned(
														bottom: 0,
														right: 0,
														child: _CornerBracket(top: false, left: false),
													),
													Positioned(
														top: cutOutSize / 2,
														left: 16,
														right: 16,
														child: Container(
															height: 2,
															decoration: BoxDecoration(
																color: const Color(0xFF0F6E56),
																borderRadius: BorderRadius.circular(999),
																boxShadow: const [
																	BoxShadow(
																		color: Color(0xCC005440),
																		blurRadius: 12,
																	),
																],
															),
														),
													),
												],
											),
										),
										const SizedBox(height: 24),
										Container(
											margin: const EdgeInsets.symmetric(horizontal: 32),
											padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
											decoration: BoxDecoration(
												color: Colors.white.withOpacity(0.95),
												borderRadius: BorderRadius.circular(12),
												border: Border.all(color: const Color(0xFFBEC9C3)),
												boxShadow: const [
													BoxShadow(
														color: Colors.black12,
														blurRadius: 8,
													),
												],
											),
											child: const Row(
												mainAxisSize: MainAxisSize.min,
												children: [
													Icon(Icons.qr_code_2, color: Color(0xFF0F6E56)),
													SizedBox(width: 12),
													Expanded(
														child: Text(
															'Arahkan kamera ke kode QR pada dok sepeda',
															style: TextStyle(
																fontFamily: 'Inter',
																fontSize: 14,
																color: Color(0xFF3F4944),
															),
														),
													),
												],
											),
										),
									],
								),
								Positioned(
									left: 0,
									right: 0,
									bottom: 0,
									child: AnimatedSlide(
										offset: _showResultSheet ? Offset.zero : const Offset(0, 1),
										duration: const Duration(milliseconds: 250),
										curve: Curves.easeOut,
										child: AnimatedOpacity(
											opacity: _showResultSheet ? 1 : 0,
											duration: const Duration(milliseconds: 200),
											child: _ResultBottomSheet(
												qrValue: _scannedQrValue,
												dockCode: StationDetailData.fromQr(_scannedQrValue).selectedDockLabel,
												stationName: StationDetailData.fromQr(_scannedQrValue).stationName,
												onStart: _handleOpenStationDetail,
												onCancel: () async {
													setState(() {
														_showResultSheet = false;
														_isScanning = true;
													});
													await _controller.start();
												},
											),
										),
									),
								),
							],
						),
					),
				],
			),
		);
	}

	Future<void> _handleOpenStationDetail() async {
		final qrValue = _scannedQrValue;
		if (qrValue.isEmpty) return;

		final stationData = StationDetailData.fromQr(qrValue);

		setState(() {
			_showResultSheet = false;
			_isScanning = true;
		});

		await Navigator.of(context).push(
			MaterialPageRoute(
				builder: (context) => StationDetailScreen(data: stationData),
			),
		);

		if (!mounted) return;
		await _controller.start();
	}
}

class _ResultBottomSheet extends StatelessWidget {
	const _ResultBottomSheet({
		required this.qrValue,
		required this.dockCode,
		required this.stationName,
		required this.onStart,
		required this.onCancel,
	});

	final String qrValue;
	final String dockCode;
	final String stationName;
	final VoidCallback onStart;
	final VoidCallback onCancel;

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: const BoxDecoration(
				color: Color(0xFFF9F9FF),
				borderRadius: BorderRadius.only(
					topLeft: Radius.circular(24),
					topRight: Radius.circular(24),
				),
				boxShadow: [
					BoxShadow(
						color: Color(0x22000000),
						blurRadius: 16,
						offset: Offset(0, -4),
					),
				],
			),
			padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
			child: SafeArea(
				top: false,
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Container(
							width: 40,
							height: 4,
							decoration: BoxDecoration(
								color: const Color(0xFFBEC9C3),
								borderRadius: BorderRadius.circular(999),
							),
						),
						const SizedBox(height: 16),
						Container(
							width: 56,
							height: 56,
							decoration: BoxDecoration(
								color: const Color(0xFFE9EDFF),
								shape: BoxShape.circle,
								border: Border.all(color: const Color(0xFFBEC9C3)),
							),
							child: const Icon(Icons.directions_bike, color: Color(0xFF005440), size: 30),
						),
						const SizedBox(height: 12),
						const Text(
							'Dok ditemukan!',
							style: TextStyle(
								fontFamily: 'Inter',
								fontSize: 20,
								fontWeight: FontWeight.w600,
								color: Color(0xFF141B2B),
							),
						),
						const SizedBox(height: 12),
						Container(
							decoration: BoxDecoration(
								color: const Color(0xFFF1F3FF),
								borderRadius: BorderRadius.circular(8),
								border: Border.all(color: const Color(0xFFBEC9C3)),
							),
							child: Column(
								children: [
									_PairRow(label: 'QR', value: qrValue),
									const _BottomSheetDivider(),
									_PairRow(label: 'Dok', value: dockCode),
									const _BottomSheetDivider(),
									_PairRow(label: 'Stasiun', value: stationName),
								],
							),
						),
						const SizedBox(height: 16),
						SizedBox(
							width: double.infinity,
							height: 44,
							child: ElevatedButton(
								onPressed: onStart,
								style: ElevatedButton.styleFrom(
									backgroundColor: const Color(0xFF0F6E56),
									foregroundColor: Colors.white,
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(8),
									),
								),
								child: Text(
									'Lihat Detail Stasiun',
									style: const TextStyle(
										fontFamily: 'Inter',
										fontSize: 14,
										fontWeight: FontWeight.w600,
									),
								),
							),
						),
						const SizedBox(height: 10),
						SizedBox(
							width: double.infinity,
							height: 44,
							child: OutlinedButton(
								onPressed: onCancel,
								style: OutlinedButton.styleFrom(
									foregroundColor: const Color(0xFF005440),
									side: const BorderSide(color: Color(0xFF7AB3FF)),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(8),
									),
								),
								child: const Text(
									'Batal',
									style: TextStyle(
										fontFamily: 'Inter',
										fontSize: 14,
										fontWeight: FontWeight.w600,
									),
								),
							),
						),
					],
				),
			),
		);
	}
}

class _PairRow extends StatelessWidget {
	const _PairRow({required this.label, required this.value});

	final String label;
	final String value;

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: [
					Text(
						label,
						style: const TextStyle(
							fontFamily: 'Inter',
							fontSize: 13,
							color: Color(0xFF3F4944),
						),
					),
					Text(
						value,
						style: const TextStyle(
							fontFamily: 'Inter',
							fontSize: 13,
							fontWeight: FontWeight.w700,
							color: Color(0xFF141B2B),
						),
					),
				],
			),
		);
	}
}

class _BottomSheetDivider extends StatelessWidget {
	const _BottomSheetDivider();

	@override
	Widget build(BuildContext context) {
		return const Divider(height: 1, thickness: 1, color: Color(0xFFBEC9C3));
	}
}

class _CornerBracket extends StatelessWidget {
	const _CornerBracket({required this.top, required this.left});

	final bool top;
	final bool left;

	@override
	Widget build(BuildContext context) {
		return Container(
			width: 56,
			height: 56,
			decoration: BoxDecoration(
				border: Border(
					top: top ? const BorderSide(color: Color(0xFF0F6E56), width: 4) : BorderSide.none,
					bottom: top ? BorderSide.none : const BorderSide(color: Color(0xFF0F6E56), width: 4),
					left: left ? const BorderSide(color: Color(0xFF0F6E56), width: 4) : BorderSide.none,
					right: left ? BorderSide.none : const BorderSide(color: Color(0xFF0F6E56), width: 4),
				),
				borderRadius: BorderRadius.only(
					topLeft: Radius.circular(top && left ? 12 : 0),
					topRight: Radius.circular(top && !left ? 12 : 0),
					bottomLeft: Radius.circular(!top && left ? 12 : 0),
					bottomRight: Radius.circular(!top && !left ? 12 : 0),
				),
			),
		);
	}
}
