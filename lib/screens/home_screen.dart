import 'package:flutter/material.dart';
import '../main.dart'; // Import main to access authService
import 'package:google_fonts/google_fonts.dart';
import '../models/driver_model.dart';
import '../models/job_order_model.dart';
import '../models/api_response.dart';
import '../models/notification_model.dart';
import '../services/job_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Services
  final JobService _jobService = JobService();
  final NotificationService _notificationService = NotificationService();

  // State
  bool _isLoading = true;
  String? _errorMessage;
  List<JobOrder> _activeOrders = [];
  List<JobOrder> _pendingOrders = [];

  // Get current driver data
  Driver? get _driver => authService.currentDriver;

  // Get initials from driver name
  String get _initials {
    if (_driver == null) return '??';
    final names = _driver!.driverName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return _driver!.driverName.length >= 2
        ? _driver!.driverName.substring(0, 2).toUpperCase()
        : '??';
  }

  // Get greeting based on time of day
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  @override
  void initState() {
    super.initState();

    // Setup notification callback to update UI
    _notificationService.setOnNotificationReceived(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Check vehicle and active orders when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVehicleAndLoadJobs();
    });
  }

  /// Check if user needs to select vehicle or can proceed directly
  /// Skip vehicle selection if there are active orders
  Future<void> _checkVehicleAndLoadJobs() async {
    // First, try to load jobs to check for active orders
    try {
      final response = await _jobService.getJobs();

      if (response.activeOrders.isNotEmpty) {
        // User has active orders, skip vehicle selection and show orders
        setState(() {
          _activeOrders = response.activeOrders;
          _pendingOrders = response.pendingOrders;
          _isLoading = false;
        });
        return;
      }

      // No active orders - check if vehicle is selected
      if (!authService.hasSelectedVehicle) {
        // No active orders and no vehicle selected, redirect to vehicle selection
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/vehicle_selection',
            arguments: 'login',
          );
        }
        return;
      }

      // Vehicle selected and no active orders, show all orders
      setState(() {
        _activeOrders = response.activeOrders;
        _pendingOrders = response.pendingOrders;
        _isLoading = false;
      });
    } on ApiError catch (e) {
      // API error - fall back to vehicle check
      if (!authService.hasSelectedVehicle) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/vehicle_selection',
            arguments: 'login',
          );
        }
      } else {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Unknown error - fall back to vehicle check
      if (!authService.hasSelectedVehicle) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/vehicle_selection',
            arguments: 'login',
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Load jobs from API (pending orders from API, active orders with dummy fallback)
  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _jobService.getJobs();
      setState(() {
        _activeOrders = response.activeOrders;
        _pendingOrders = response.pendingOrders; // From API
        _isLoading = false;
      });
    } on ApiError catch (e) {
      // API error - use dummy active orders as fallback, no pending orders
      debugPrint('API Error: ${e.message}, using dummy active orders');
      setState(() {
        _activeOrders = DummyJobOrders.getActiveOrders();
        _pendingOrders = []; // No dummy pending orders
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      // Error - use dummy active orders as fallback, no pending orders
      debugPrint('Error: $e, using dummy active orders');
      setState(() {
        _activeOrders = DummyJobOrders.getActiveOrders();
        _pendingOrders = []; // No dummy pending orders
        _errorMessage = null;
        _isLoading = false;
      });
    }
  }

  /// Accept a pending order
  Future<void> _acceptOrder(JobOrder order) async {
    try {
      await _jobService.acceptOrder(
        order.jobOrderId,
        vehicleId: authService.selectedVehicleId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order.jobOrderId} berhasil diterima'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload jobs
      _loadJobs();
    } on ApiError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  /// Reject a pending order
  Future<void> _rejectOrder(JobOrder order, {String? reason}) async {
    try {
      await _jobService.rejectOrder(order.jobOrderId, reason: reason);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order.jobOrderId} ditolak'),
          backgroundColor: Colors.orange,
        ),
      );

      // Reload jobs
      _loadJobs();
    } on ApiError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  /// Show reject reason dialog
  Future<void> _showRejectDialog(JobOrder order) async {
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tolak Order'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Apakah Anda yakin ingin menolak order ${order.jobOrderId}?',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Alasan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Tolak'),
              ),
            ],
          ),
    );

    if (result == true) {
      _rejectOrder(
        order,
        reason: reasonController.text.isNotEmpty ? reasonController.text : null,
      );
    }
  }

  /// Show notification popup
  void _showNotificationPopup() {
    // Mark all as read when opening
    _notificationService.markAllAsRead();
    setState(() {});

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Notifikasi',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_notificationService.hasNotifications)
                              TextButton(
                                onPressed: () {
                                  _notificationService.clearNotifications();
                                  Navigator.pop(context);
                                  setState(() {});
                                },
                                child: Text(
                                  'Hapus Semua',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(),
                      // Notification list
                      Expanded(
                        child:
                            _notificationService.hasNotifications
                                ? ListView.builder(
                                  controller: scrollController,
                                  itemCount:
                                      _notificationService.notifications.length,
                                  itemBuilder: (context, index) {
                                    final notification =
                                        _notificationService
                                            .notifications[index];
                                    return _buildNotificationItem(notification);
                                  },
                                )
                                : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.notifications_off_outlined,
                                        size: 64,
                                        color: Colors.grey[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tidak ada notifikasi',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  /// Build notification item widget
  Widget _buildNotificationItem(NotificationItem notification) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (notification.orderId != null) {
          // Navigate to the order - refresh jobs to show it
          _loadJobs();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue.shade50,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    notification.isOrderNotification
                        ? Colors.green.shade100
                        : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                notification.isOrderNotification
                    ? Icons.local_shipping
                    : Icons.notifications,
                color:
                    notification.isOrderNotification
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.formattedTime,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            if (notification.orderId != null)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If no vehicle is selected, show a loading indicator while the redirection happens
    if (!authService.hasSelectedVehicle) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset(
          'assets/images/logo.png',
          height: 40,
        ),
        actions: [
          // Vehicle info
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: Colors.blue.shade600,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authService.selectedVehicleId ?? 'Unknown',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    Text(
                      'Kendaraan',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  onSelected: (value) {
                    if (value == 'change') {
                      Navigator.pushReplacementNamed(
                        context,
                        '/vehicle_selection',
                        arguments: 'home',
                      );
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'change',
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping, size: 18),
                              SizedBox(width: 8),
                              Text('Ganti Kendaraan'),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
          // Notification button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
                onPressed: _showNotificationPopup,
              ),
              if (_notificationService.unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _notificationService.unreadCount > 9
                          ? '9+'
                          : _notificationService.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF003D9E),
              child: Text(
                _initials,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              Text(
                _driver?.driverName ?? 'Driver',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Vehicle status row
              Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    _activeOrders.isNotEmpty
                        ? 'Sedang dalam perjalanan'
                        : 'Menunggu order',
                    style: const TextStyle(color: Colors.blue),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/vehicle_selection',
                        arguments: 'home',
                      );
                    },
                    icon: const Icon(Icons.local_shipping_outlined, size: 16),
                    label: const Text('Ganti Kendaraan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Loading or Error state
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadJobs,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Active Orders Section
                const Text(
                  'Order Aktif',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                
                if (_activeOrders.isEmpty)
                  _buildEmptyState(
                    'Tidak ada order aktif',
                    Icons.inbox_outlined,
                  )
                else
                  ..._activeOrders.map((order) => _buildActiveOrderCard(order)),

                const SizedBox(height: 24),

                // Pending Orders Section
                const Text(
                  'Order Pending',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),

                if (_pendingOrders.isEmpty)
                  _buildEmptyState(
                    'Tidak ada order pending',
                    Icons.hourglass_empty,
                  )
                else
                  ..._pendingOrders.map(
                    (order) => _buildPendingOrderCard(order),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  /// Build active order card from JobOrder
  Widget _buildActiveOrderCard(JobOrder order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.blue[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusLabel(order.status),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        order.goodsDesc,
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.jobOrderId,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      order.formattedWeight,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      order.orderType,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Pickup location
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        order.pickupAddress,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Delivery location
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        order.deliveryAddress,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Customer info
            Row(
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (order.customerPhone != null)
                  Text(
                    order.customerPhone!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to maps with this order
                    Navigator.pushNamed(context, '/maps', arguments: order);
                  },
                  icon: const Icon(Icons.navigation, size: 18),
                  label: const Text('Navigasi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[800],
                    side: BorderSide(color: Colors.blue[800]!),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to delivery proof form
                    Navigator.pushNamed(
                      context,
                      '/delivery_proof',
                      arguments: order,
                    );
                  },
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Selesai'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build pending order card from JobOrder
  Widget _buildPendingOrderCard(JobOrder order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.jobOrderId,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.orderType,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.goodsDesc,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              order.formattedWeight,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Divider(height: 24),

            // Pickup
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        order.pickupAddress,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Delivery
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        order.deliveryAddress,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Customer info
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(order.customerName),
              ],
            ),
            const SizedBox(height: 16),
            
            // Accept/Reject buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Terima'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get human readable status label
  String _getStatusLabel(String status) {
    switch (status) {
      case 'Processing':
        return 'Menuju Pickup';
      case 'Pickup Complete':
        return 'Barang Diambil';
      case 'In Transit':
        return 'Dalam Perjalanan';
      case 'Nearby':
        return 'Hampir Sampai';
      case 'Delivered':
        return 'Selesai';
      default:
        return status;
    }
  }

  /// Build status badge
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Processing':
        bgColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        break;
      case 'Pickup Complete':
        bgColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        break;
      case 'In Transit':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'Nearby':
        bgColor = Colors.teal.shade100;
        textColor = Colors.teal.shade800;
        break;
      case 'Delivered':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}