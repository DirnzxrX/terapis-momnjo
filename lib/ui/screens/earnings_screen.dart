import 'package:flutter/material.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final Color primaryPink = const Color(0xFFF48FB1);
  String _selectedTab = 'Rincian'; // Default tab

  // Data dummy untuk list riwayat pendapatan
  final List<Map<String, dynamic>> _earningsHistory = [
    {
      'date': '13 Mei',
      'time': '10.00',
      'name': 'Dewi Lestari',
      'amount': 'Rp 150.000',
      'status': 'Completed',
    },
    {
      'date': '13 Mei',
      'time': '08.00',
      'name': 'Siti Aisyah',
      'amount': 'Rp 100.000',
      'status': 'Completed',
    },
    {
      'date': '12 Mei',
      'time': '13.00',
      'name': 'Anita Putri',
      'amount': 'Rp 120.000',
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Earnings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Header Periode
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Periode',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Row(
                  children: const [
                    Text(
                      'Mei 2024',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: Colors.black87),
                  ],
                ),
              ],
            ),
          ),

          // 2. Card Total Earnings
          _buildEarningsCard(),
          const SizedBox(height: 24),

          // 3. Custom Tabs (Rincian, Bonus, Payout)
          _buildTabs(),
          const SizedBox(height: 16),

          // 4. List Riwayat Transaksi
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _earningsHistory.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFFEEEEEE)),
              itemBuilder: (context, index) {
                final item = _earningsHistory[index];
                return _buildHistoryItem(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildEarningsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryPink,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Earnings',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rp 8.250.000',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSubEarning('Hari Ini', 'Rp 850.000'),
                _buildVerticalDivider(),
                _buildSubEarning('Minggu Ini', 'Rp 3.250.000'),
                _buildVerticalDivider(),
                _buildSubEarning('Bulan Ini', 'Rp 8.250.000'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubEarning(String label, String amount) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.5),
    );
  }

  Widget _buildTabs() {
    final tabs = ['Rincian', 'Bonus', 'Payout'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedTab == tab;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? primaryPink.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? primaryPink : Colors.grey.shade300,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected ? primaryPink : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tanggal & Waktu
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['date'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  item['time'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Nama Customer
          Expanded(
            child: Text(
              item['name'],
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Amount & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item['amount'],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['status'],
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}