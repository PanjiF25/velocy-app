import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:velocy_app/core/utils/navigation_helper.dart';
import 'package:velocy_app/ui/user/stations/station_detail_screen.dart';
import 'package:velocy_app/core/utils/qr_helper.dart';
import 'package:velocy_app/core/theme/theme_utils.dart';
import 'package:velocy_app/core/l10n/app_localizations.dart';
import 'package:velocy_app/ui/common/widgets/exit_confirmation_wrapper.dart';

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

		return ExitConfirmationWrapper(
			child: Scaffold(
				backgroundColor: AppTheme.bg(context),
			appBar: AppBar(
				backgroundColor: AppTheme.bg(context),
				elevation: 0,
				scrolledUnderElevation: 0,
				leading: IconButton(
					icon: Icon(Icons.arrow_back, color: AppTheme.textMuted(context)),
					onPressed: () => switchToTab(context, 0),
				),
				centerTitle: true,
				title: Text(
					AppLocalizations.isIndo ? 'Pindai QR' : 'Scan QR',
					style: TextStyle(
						fontFamily: 'Inter',
						fontSize: 20,
						fontWeight: FontWeight.w700,
						color: AppTheme.primary(context),
					),
				),
				actions: [
					IconButton(
						icon: Icon(Icons.language, color: AppTheme.textMuted(context)),
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
				backgroundColor: AppTheme.surface(context),
				indicatorColor: AppTheme.primary(context),
				destinations: [
					NavigationDestination(
						icon: Icon(Icons.home_outlined, color: AppTheme.textMuted(context)),
						selectedIcon: Icon(Icons.home, color: AppTheme.surface(context)),
						label: AppLocalizations.tr('NavHome'),
					),
					NavigationDestination(
						icon: Icon(Icons.qr_code_scanner, color: AppTheme.textMuted(context)),
						selectedIcon: Icon(Icons.qr_code_scanner, color: AppTheme.surface(context)),
						label: AppLocalizations.tr('NavRent'),
					),
					NavigationDestination(
						icon: Icon(Icons.directions_bike, color: AppTheme.textMuted(context)),
						selectedIcon: Icon(Icons.directions_bike, color: AppTheme.surface(context)),
						label: AppLocalizations.tr('NavTrip'),
					),
					NavigationDestination(
						icon: Icon(Icons.person_outline, color: AppTheme.textMuted(context)),
						selectedIcon: Icon(Icons.person, color: AppTheme.surface(context)),
						label: AppLocalizations.tr('NavProfile'),
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
																color: AppTheme.primary(context),
																borderRadius: BorderRadius.circular(999),
																boxShadow: [
																	BoxShadow(
																		color: AppTheme.primary(context).withOpacity(0.8),
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
												color: AppTheme.surface(context).withOpacity(0.95),
												borderRadius: BorderRadius.circular(12),
												border: Border.all(color: AppTheme.outline(context)),
												boxShadow: [
                                                    if (!AppTheme.isDark(context))
    													const BoxShadow(
    														color: Colors.black12,
    														blurRadius: 8,
    													),
												],
											),
											child: Row(
												mainAxisSize: MainAxisSize.min,
												children: [
													Icon(Icons.qr_code_2, color: AppTheme.primary(context)),
													const SizedBox(width: 12),
													Expanded(
														child: Text(
															AppLocalizations.tr('AlignQR'),
															style: TextStyle(
																fontFamily: 'Inter',
																fontSize: 14,
																color: AppTheme.textMuted(context),
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
												dockCode: QrHelper.parseQr(_scannedQrValue)['dockLabel'] ?? '',
												stationName: QrHelper.parseQr(_scannedQrValue)['stationName'] ?? '',
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
		));
	}

	Future<void> _handleOpenStationDetail() async {
		final qrValue = _scannedQrValue;
		if (qrValue.isEmpty) return;

		setState(() {
			_showResultSheet = false;
			_isScanning = true;
		});

		await Navigator.of(context).push(
			MaterialPageRoute(
				builder: (context) => StationDetailScreen(qrValue: qrValue),
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
			decoration: BoxDecoration(
				color: AppTheme.surface(context),
				borderRadius: const BorderRadius.only(
					topLeft: Radius.circular(24),
					topRight: Radius.circular(24),
				),
				boxShadow: [
                    if (!AppTheme.isDark(context))
    					const BoxShadow(
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
								color: AppTheme.outline(context),
								borderRadius: BorderRadius.circular(999),
							),
						),
						const SizedBox(height: 16),
						Container(
							width: 56,
							height: 56,
							decoration: BoxDecoration(
								color: AppTheme.surfaceVariant(context),
								shape: BoxShape.circle,
								border: Border.all(color: AppTheme.outline(context)),
							),
							child: Icon(Icons.directions_bike, color: AppTheme.primary(context), size: 30),
						),
						const SizedBox(height: 12),
						Text(
							AppLocalizations.isIndo ? 'Dok ditemukan!' : 'Dock found!',
							style: TextStyle(
								fontFamily: 'Inter',
								fontSize: 20,
								fontWeight: FontWeight.w600,
								color: AppTheme.textMain(context),
							),
						),
						const SizedBox(height: 12),
						Container(
							decoration: BoxDecoration(
								color: AppTheme.surfaceVariant(context),
								borderRadius: BorderRadius.circular(8),
								border: Border.all(color: AppTheme.outline(context)),
							),
							child: Column(
								children: [
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
									backgroundColor: AppTheme.primary(context),
									foregroundColor: Colors.white,
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(8),
									),
								),
								child: Text(
									AppLocalizations.isIndo ? 'Lihat Detail Stasiun' : 'View Station Details',
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
									foregroundColor: AppTheme.primary(context),
									side: BorderSide(color: AppTheme.primary(context)),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(8),
									),
								),
								child: Text(
									AppLocalizations.tr('Cancel'),
									style: const TextStyle(
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
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						label,
						style: TextStyle(
							fontFamily: 'Inter',
							fontSize: 13,
							color: AppTheme.textMuted(context),
						),
					),
					const SizedBox(width: 16),
					Expanded(
						child: Text(
							value,
							textAlign: TextAlign.right,
							style: TextStyle(
								fontFamily: 'Inter',
								fontSize: 13,
								fontWeight: FontWeight.w700,
								color: AppTheme.textMain(context),
							),
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
		return Divider(height: 1, thickness: 1, color: AppTheme.outline(context));
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
					top: top ? BorderSide(color: AppTheme.primary(context), width: 4) : BorderSide.none,
					bottom: top ? BorderSide.none : BorderSide(color: AppTheme.primary(context), width: 4),
					left: left ? BorderSide(color: AppTheme.primary(context), width: 4) : BorderSide.none,
					right: left ? BorderSide.none : BorderSide(color: AppTheme.primary(context), width: 4),
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
