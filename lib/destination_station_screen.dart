import 'package:flutter/material.dart';

class DestinationStationScreen extends StatefulWidget {
  const DestinationStationScreen({
    super.key,
    required this.originStationName,
    required this.originDockLabel,
    required this.originDockCode,
  });

  final String originStationName;
  final String originDockLabel;
  final String originDockCode;

  @override
  State<DestinationStationScreen> createState() => _DestinationStationScreenState();
}

class _DestinationStationScreenState extends State<DestinationStationScreen> {
  late final List<DestinationStationItem> _stations;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _stations = const [
      DestinationStationItem(
        name: 'Gedung Rektorat',
        distance: '250m dari lokasi anda',
        availableDocks: 5,
        totalDocks: 10,
        occupancyText: 'Terisi: 5/10',
        availableColor: Color(0xFF137333),
        barColor: Color(0xFF0F6E56),
        statusLabel: '5 dok tersedia',
        isFull: false,
      ),
      DestinationStationItem(
        name: 'Perpustakaan Pusat',
        distance: '400m dari lokasi anda',
        availableDocks: 2,
        totalDocks: 10,
        occupancyText: 'Terisi: 8/10',
        availableColor: Color(0xFF137333),
        barColor: Color(0xFFF59E0B),
        statusLabel: '2 dok tersedia',
        isFull: false,
      ),
      DestinationStationItem(
        name: 'Fakultas Teknik',
        distance: '550m dari lokasi anda',
        availableDocks: 1,
        totalDocks: 12,
        occupancyText: 'Terisi: 11/12',
        availableColor: Color(0xFF137333),
        barColor: Color(0xFFEA580C),
        statusLabel: '1 dok tersedia',
        isFull: false,
      ),
      DestinationStationItem(
        name: 'Asrama Mahasiswa',
        distance: '800m dari lokasi anda',
        availableDocks: 0,
        totalDocks: 15,
        occupancyText: 'Terisi: 15/15',
        availableColor: Color(0xFFB91C1C),
        barColor: Color(0xFFEF4444),
        statusLabel: 'Penuh',
        isFull: true,
      ),
      DestinationStationItem(
        name: 'Fakultas MIPA',
        distance: '1.2km dari lokasi anda',
        availableDocks: 0,
        totalDocks: 8,
        occupancyText: 'Terisi: 8/8',
        availableColor: Color(0xFFB91C1C),
        barColor: Color(0xFFEF4444),
        statusLabel: 'Penuh',
        isFull: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final selectedStation = _stations[_selectedIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3F4944)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Pilih Stasiun Tujuan',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBEC9C3)),
                    ),
                    child: const Text(
                      'Pilih stasiun terdekat untuk mengembalikan sepeda. Pastikan terdapat slot parkir (dock) yang tersedia.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF3F4944),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dari ${widget.originStationName} · ${widget.originDockLabel} (${widget.originDockCode})',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3F4944),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    itemCount: _stations.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final station = _stations[index];
                      final isSelected = index == _selectedIndex;

                      return _DestinationStationCard(
                        item: station,
                        isSelected: isSelected,
                        onTap: station.isFull
                            ? null
                            : () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9FF),
              border: Border(top: BorderSide(color: Color(0xFFBEC9C3))),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: selectedStation.isFull
                      ? null
                      : () {
                          Navigator.of(context).pop(selectedStation);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F6E56),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFDCE2F7),
                    disabledForegroundColor: const Color(0xFF6F7A74),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    selectedStation.isFull ? 'Stasiun penuh' : 'Pilih Stasiun Tujuan',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DestinationStationItem {
  const DestinationStationItem({
    required this.name,
    required this.distance,
    required this.availableDocks,
    required this.totalDocks,
    required this.occupancyText,
    required this.availableColor,
    required this.barColor,
    required this.statusLabel,
    required this.isFull,
  });

  final String name;
  final String distance;
  final int availableDocks;
  final int totalDocks;
  final String occupancyText;
  final Color availableColor;
  final Color barColor;
  final String statusLabel;
  final bool isFull;
}

class _DestinationStationCard extends StatelessWidget {
  const _DestinationStationCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final DestinationStationItem item;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF0F6E56) : const Color(0xFFBEC9C3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.isFull ? const Color(0xFFDCE2F7) : const Color(0xFF0F6E56),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_bike,
                  color: item.isFull ? const Color(0xFF9AA3A0) : Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: item.isFull ? const Color(0xFF6F7A74) : const Color(0xFF141B2B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isFull
                                ? const Color(0xFFFFDAD6)
                                : const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: item.isFull
                                  ? const Color(0xFFF9BDBB)
                                  : const Color(0xFFCEEAD6),
                            ),
                          ),
                          child: Text(
                            item.statusLabel,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: item.isFull ? const Color(0xFFBA1A1A) : const Color(0xFF137333),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.distance,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: item.isFull ? const Color(0xFF9AA3A0) : const Color(0xFF3F4944),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.totalDocks == 0 ? 0 : item.availableDocks / item.totalDocks,
              minHeight: 6,
              backgroundColor: const Color(0xFFDCE2F7),
              valueColor: AlwaysStoppedAnimation<Color>(item.barColor),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              item.occupancyText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: item.isFull ? const Color(0xFFBA1A1A) : const Color(0xFF3F4944),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Opacity(opacity: 0.6, child: IgnorePointer(child: card));
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: card,
    );
  }
}
