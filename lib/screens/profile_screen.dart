import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // Import main to access authService
import '../models/driver_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  // Get current driver data
  Driver? get _driver => authService.currentDriver;

  // Get driver status as bool for switch
  bool get _isDriverActive =>
      _driver?.status == 'Available' || _driver?.status == 'On Duty';

  // Get initials from name
  String get _initials {
    if (_driver == null) return '?';
    final names = _driver!.driverName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return _driver!.driverName.isNotEmpty
        ? _driver!.driverName[0].toUpperCase()
        : '?';
  }

  Future<void> _toggleDriverStatus(bool isActive) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newStatus =
          isActive ? DriverStatus.available : DriverStatus.offDuty;
      await authService.updateStatus(newStatus);
      setState(() {}); // Refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF003D9E),
                          child: Text(
                            _initials,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _driver?.driverName ?? 'Driver',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _driver?.phone ?? '-',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _driver?.email ?? '-',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.local_shipping_outlined,
                          '${_driver?.statistics?.totalOrders ?? 0}',
                          'Total Order',
                        ),
                        _buildStatItem(
                          Icons.check_circle_outline,
                          '${_driver?.statistics?.totalDelivered ?? 0}',
                          'Delivered',
                        ),
                        _buildStatItem(
                          Icons.straighten,
                          '${_driver?.statistics?.totalDistanceKm.toStringAsFixed(0) ?? '0'} km',
                          'Jarak',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Status Driver Switch
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Status Driver',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _isDriverActive
                                          ? Colors.green.shade100
                                          : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _driver?.status ?? 'Unknown',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        _isDriverActive
                                            ? Colors.green.shade700
                                            : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isDriverActive
                                ? 'Anda sedang aktif dan siap menerima order'
                                : 'Anda sedang offline',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Switch(
                          value: _isDriverActive,
                          onChanged: _toggleDriverStatus,
                          activeColor: const Color(0xFF021E7B),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Settings
              _buildMenuCard(
                icon: Icons.settings_outlined,
                title: 'Pengaturan',
                subtitle: 'Ubah preferensi dan notifikasi',
                onTap: () {},
              ),
              const SizedBox(height: 16),

              // Help
              _buildMenuCard(
                icon: Icons.help_outline,
                title: 'Bantuan',
                subtitle: 'FAQ dan dukungan pelanggan',
                onTap: () {},
              ),
              const SizedBox(height: 16),

              // Logout
              _buildMenuCard(
                icon: Icons.logout,
                title: 'Keluar',
                subtitle: 'Logout dari aplikasi',
                titleColor: Colors.red,
                iconColor: Colors.red,
                onTap: () {
                  // Handle logout
                  authService.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
              
              const SizedBox(height: 32),
              Text(
                'SendPick Driver v1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color titleColor = Colors.black,
    Color iconColor = Colors.black87,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.black87, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }
}
