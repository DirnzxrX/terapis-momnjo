import 'package:flutter/material.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final Color mockupPink = const Color(0xFFE8647C); 
  final Color bgLight = const Color(0xFFFFF7F7); 

  String _selectedTab = 'Rincian'; 

  // --- DATA DUMMY: Riwayat Pendapatan (Rincian/Bonus) ---
  final List<Map<String, dynamic>> _earningsHistory = [
    {'date': '13 Mei', 'time': '10.00', 'name': 'Dewi Lestari', 'amount': 'Rp 150.000', 'status': 'Completed'},
    {'date': '13 Mei', 'time': '08.00', 'name': 'Siti Aisyah', 'amount': 'Rp 100.000', 'status': 'Completed'},
    {'date': '12 Mei', 'time': '13.00', 'name': 'Anita Putri', 'amount': 'Rp 120.000', 'status': 'Completed'},
  ];

  // --- DATA DUMMY: Riwayat Penarikan Dana (Payout) ---
  final List<Map<String, dynamic>> _payoutHistory = [
    {'date': '18 Apr 2026', 'id': 'PO240418001', 'amount': 'Rp 1.500.000', 'status': 'Pending', 'est': 'Est. transfer: 20 Apr 2026'},
    {'date': '10 Apr 2026', 'id': 'PO240410002', 'amount': 'Rp 800.000', 'status': 'Paid', 'est': null},
    {'date': '18 Mar 2026', 'id': 'PO240318005', 'amount': 'Rp 2.100.000', 'status': 'Paid', 'est': null},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pendapatan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Icon(Icons.history_toggle_off, color: Colors.grey.shade700, size: 26),
                ],
              ),
            ),

            // 2. Row Periode (Hanya muncul jika BUKAN di tab Payout sesuai mockup)
            if (_selectedTab != 'Payout')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Periode', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    Row(
                      children: [
                        const Text('Mei 2024', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            if (_selectedTab == 'Payout')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Period: This Month', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                      Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade700, size: 20),
                    ],
                  ),
                ),
              ),

            // 3. Card Dinamis (Berubah berdasarkan Tab yang ditekan)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _selectedTab == 'Payout' ? _buildPayoutCard() : _buildEarningsCard(),
            ),
            
            const SizedBox(height: 24),

            // 4. Custom Tabs (TETAP DI POSISINYA SESUAI INSTRUKSI)
            _buildTabs(),
            const SizedBox(height: 24),

            // 5. Container List Riwayat Dinamis
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: _selectedTab == 'Payout' 
                  ? _buildPayoutListView() 
                  : _buildEarningsListView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS: KARTU ATAS ---

  // Bentuk Kartu saat Tab 'Rincian' atau 'Bonus'
  Widget _buildEarningsCard() {
    return Container(
      key: const ValueKey('EarningsCard'),
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: mockupPink,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: mockupPink.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text('Total Pendapatan', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                const Text('Rp 8.250.000', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(2, 0, 2, 2),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSubEarning('Hari Ini', 'Rp 850.000'),
                Container(width: 1, height: 40, color: Colors.grey.shade200), 
                _buildSubEarning('Minggu Ini', 'Rp 3.250.000'),
                Container(width: 1, height: 40, color: Colors.grey.shade200), 
                _buildSubEarning('Bulan Ini', 'Rp 8.250.000'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Bentuk Kartu Baru saat Tab 'Payout' (Sesuai Gambar Desain Anda)
  Widget _buildPayoutCard() {
    return Container(
      key: const ValueKey('PayoutCard'),
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: mockupPink,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: mockupPink.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text('Available Balance', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Rp 2.350.000', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Ready to withdraw', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          // =========================================================================
          // TOMBOL REQUEST PAYOUT YANG SUDAH TERSAMBUNG
          // =========================================================================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // PERBAIKAN LOGIKA: Menggunakan async-await untuk menunggu hasil dari form
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/request_payout');
                
                // Jika form payout mengembalikan nilai "true" (transaksi dikonfirmasi sukses)
                if (result == true) {
                  setState(() {
                    _selectedTab = 'Payout'; // Paksa tab agar tetap berada di Payout
                  });
                  
                  // Secara visual beri tahu user bahwa data di tab ini telah diperbarui
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Riwayat Penarikan Dana sedang diperbarui...'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC2185B), 
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(' Request Payout ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubEarning(String label, String amount) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(amount, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- WIDGET BUILDERS: TABS ---

  Widget _buildTabs() {
    final tabs = ['Treatment', 'Paket', 'Payout'];
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? mockupPink : Colors.white,
                  borderRadius: BorderRadius.circular(20), 
                  boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                alignment: Alignment.center,
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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

  // --- WIDGET BUILDERS: LIST VIEW ---

  Widget _buildEarningsListView() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: _earningsHistory.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Divider(color: Colors.grey.shade200, height: 1),
      ),
      itemBuilder: (context, index) {
        final item = _earningsHistory[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 95,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text('${item['date']} ${item['time']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item['amount'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Text(item['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade600)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPayoutListView() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: _payoutHistory.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Divider(color: Colors.grey.shade200, height: 1),
      ),
      itemBuilder: (context, index) {
        final item = _payoutHistory[index];
        bool isPending = item['status'] == 'Pending';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['date'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('ID: ${item['id']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 12),
                Text(item['amount'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                if (item['est'] != null) ...[
                  const SizedBox(height: 4),
                  Text(item['est'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ]
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.amber.shade100 : Colors.green.shade100, 
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6, height: 6, 
                        decoration: BoxDecoration(shape: BoxShape.circle, color: isPending ? Colors.amber.shade700 : Colors.green.shade700),
                      ),
                      const SizedBox(width: 6),
                      Text(item['status'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPending ? Colors.amber.shade800 : Colors.green.shade800)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ],
        );
      },
    );
  }
}