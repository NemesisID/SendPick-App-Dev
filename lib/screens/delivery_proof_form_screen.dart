import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import '../models/order.dart';
import '../models/job_order_model.dart';
import '../models/api_response.dart';
import '../services/job_service.dart';

class DeliveryProofFormScreen extends StatefulWidget {
  final String? imagePath;
  // Order data - can be single order or selected from list
  final Order? order;
  final List<Order>? availableOrders; // For LTL - multiple orders
  final Function(String orderId)? onOrderCompleted;
  
  // Legacy support - individual fields
  final String orderId;
  final String orderDate;
  final String namaBarang;
  final String customerName;
  final double beratKg;
  final String tipeOrderan;
  
  const DeliveryProofFormScreen({
    super.key, 
    this.imagePath,
    this.order,
    this.availableOrders,
    this.onOrderCompleted,
    this.orderId = 'SP-2025-001',
    this.orderDate = 'Senin, 16 Desember 2025',
    this.namaBarang = 'Paket Elektronik',
    this.customerName = 'PT. Sendpick Indonesia',
    this.beratKg = 2.5,
    this.tipeOrderan = 'Express Delivery',
  });

  @override
  State<DeliveryProofFormScreen> createState() => _DeliveryProofFormScreenState();
}

class _DeliveryProofFormScreenState extends State<DeliveryProofFormScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentImagePath;
  
  // Services
  final JobService _jobService = JobService();
  
  // Form controllers - only editable field
  final _namaPenerimaController = TextEditingController();
  final _notesController = TextEditingController();

  // Loading state
  bool _isSubmitting = false;
  
  // Selected order for LTL
  Order? _selectedOrder;
  List<Order> _pendingOrders = [];
  
  // JobOrder from API (if passed)
  JobOrder? _jobOrder;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentImagePath = widget.imagePath;
    
    // Initialize selected order
    if (widget.order != null) {
      _selectedOrder = widget.order;
    }
    
    // Filter available orders to only show pending/in-progress
    if (widget.availableOrders != null) {
      _pendingOrders = widget.availableOrders!
          .where((o) => o.status != OrderStatus.completed)
          .toList();
      if (_pendingOrders.isNotEmpty && _selectedOrder == null) {
        _selectedOrder = _pendingOrders.first;
      }
    }
    
    // Check for JobOrder passed via route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is JobOrder) {
        setState(() {
          _jobOrder = args;
        });
      }
    });
    
    // Listen to tab changes to update UI
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _namaPenerimaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Get current order data (from JobOrder, Order object, or legacy fields)
  String get _orderId =>
      _jobOrder?.jobOrderId ?? _selectedOrder?.id ?? widget.orderId;
  String get _orderDate =>
      _jobOrder?.shipDate ?? _selectedOrder?.formattedDate ?? widget.orderDate;
  String get _namaBarang =>
      _jobOrder?.goodsDesc ?? _selectedOrder?.namaBarang ?? widget.namaBarang;
  String get _customerName =>
      _jobOrder?.customerName ??
      _selectedOrder?.customerName ??
      widget.customerName;
  double get _beratKg =>
      _jobOrder?.goodsWeight ?? _selectedOrder?.beratKg ?? widget.beratKg;
  String get _tipeOrderan => _selectedOrder?.tipeOrderan ?? widget.tipeOrderan;

  Future<void> _retakePhoto() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin mengambil ulang foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF021E7B),
            ),
            child: const Text('Ya, Ambil Ulang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Navigate to scan screen
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const _RetakeScanScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _currentImagePath = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnPODTab = _tabController.index == 1;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF021E7B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Order',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Order ID Card with Dropdown for LTL
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Order selector for LTL
                if (_pendingOrders.length > 1) ...[
                  _buildOrderDropdown(),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                ],
                
                const Text(
                  'ORDER ID',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF021E7B),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _orderId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _orderDate,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF021E7B),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF021E7B),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                    tabs: const [
                      Tab(text: 'Detail Order'),
                      Tab(text: 'Proof of Delivery'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailOrderTab(),
                _buildProofOfDeliveryTab(),
              ],
            ),
          ),
          
          // Dynamic Button (Next or Selesai)
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton(
                onPressed: isOnPODTab ? _onSelesaiPressed : _onNextPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOnPODTab 
                      ? const Color(0xFF4CAF50) // Green for Selesai
                      : const Color(0xFF021E7B), // Blue for Next
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isOnPODTab ? 'Selesai' : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_shipping, size: 18, color: Color(0xFF021E7B)),
            const SizedBox(width: 8),
            const Text(
              'Pilih Order untuk POD',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF021E7B),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_pendingOrders.length} order',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Order>(
              value: _selectedOrder,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              items: _pendingOrders.map((order) {
                return DropdownMenuItem<Order>(
                  value: order,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: order.status == OrderStatus.inProgress
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.id,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: order.status == OrderStatus.inProgress
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customerName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (Order? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedOrder = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailOrderTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Nama Penerima - EDITABLE
          _buildFormField(
            label: 'NAMA PENERIMA',
            isRequired: true,
            child: TextField(
              controller: _namaPenerimaController,
              decoration: _inputDecoration('Masukkan nama penerima'),
            ),
          ),
          const SizedBox(height: 16),
          // Nama Barang - READ ONLY
          _buildFormField(
            label: 'NAMA BARANG',
            isRequired: false,
            child: _buildReadOnlyField(_namaBarang),
          ),
          const SizedBox(height: 16),
          // Customer Name - READ ONLY
          _buildFormField(
            label: 'CUSTOMER NAME',
            isRequired: false,
            child: _buildReadOnlyField(_customerName),
          ),
          const SizedBox(height: 16),
          // Berat (kg) - READ ONLY
          _buildFormField(
            label: 'BERAT (KG)',
            isRequired: false,
            child: _buildReadOnlyField('$_beratKg kg'),
          ),
          const SizedBox(height: 16),
          // Tipe Orderan - READ ONLY
          _buildFormField(
            label: 'TIPE ORDERAN',
            isRequired: false,
            child: _buildReadOnlyField(_tipeOrderan),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildProofOfDeliveryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // POD Label
          const Text(
            'POD',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          // Image Preview Container
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _currentImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_currentImagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholder();
                      },
                    ),
                  )
                : _buildPlaceholder(),
          ),
          
          const SizedBox(height: 16),
          
          // Ambil Ulang Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF021E7B),
              borderRadius: BorderRadius.circular(6),
            ),
            child: InkWell(
              onTap: _retakePhoto,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.refresh, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Ambil Ulang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.camera_alt_outlined,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: isRequired
                ? [
                    const TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF021E7B), width: 2),
      ),
    );
  }

  void _onNextPressed() {
    // Move to POD tab
    _tabController.animateTo(1);
  }

  Future<void> _onSelesaiPressed() async {
    // Validate receiver name
    if (_namaPenerimaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi nama penerima terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      _tabController.animateTo(0); // Go back to detail tab
      return;
    }

    // Validate image
    if (_currentImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon ambil foto bukti pengiriman'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If we have a JobOrder, upload POD via API
    if (_jobOrder != null) {
      await _uploadPodToApi();
      return;
    }

    // Legacy behavior - notify completion callback if available
    if (widget.onOrderCompleted != null) {
      widget.onOrderCompleted!(_orderId);
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pengiriman $_orderId berhasil dikonfirmasi!'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
    
    // Navigate back to home
    Navigator.popUntil(context, (route) => route.isFirst);
  }
  
  /// Upload Proof of Delivery to API
  Future<void> _uploadPodToApi() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // First update status to Delivered
      await _jobService.updateJobStatus(
        _jobOrder!.jobOrderId,
        'Delivered',
        notes: 'Pengiriman selesai',
      );

      // Then upload POD
      await _jobService.uploadProofOfDelivery(
        _jobOrder!.jobOrderId,
        recipientName: _namaPenerimaController.text.trim(),
        photo: _currentImagePath != null ? File(_currentImagePath!) : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengiriman ${_jobOrder!.jobOrderId} berhasil dikonfirmasi!',
          ),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );

      // Navigate back to home
      Navigator.popUntil(context, (route) => route.isFirst);
    } on ApiError catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

// Retake Scan Screen - simplified camera screen for retaking photos
class _RetakeScanScreen extends StatefulWidget {
  const _RetakeScanScreen();

  @override
  State<_RetakeScanScreen> createState() => _RetakeScanScreenState();
}

class _RetakeScanScreenState extends State<_RetakeScanScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> _cameras = [];
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _controller = CameraController(
          _cameras[0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        _initializeControllerFuture = _controller!.initialize().then((_) {
          if (mounted) setState(() {});
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, image.path);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        Navigator.pop(context, image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_controller != null && _controller!.value.isInitialized)
              SizedBox.expand(child: CameraPreview(_controller!))
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),

            // Header
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
                  ),
                  const Text(
                    'Ambil Ulang Foto',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            // Scanner Overlay
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            // Flash Icon
            Positioned(
              bottom: 180,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _toggleFlash,
                  child: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),

            // Bottom Controls
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  height: 80,
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery Button
                      GestureDetector(
                        onTap: _pickFromGallery,
                        child: const Icon(Icons.image_outlined, color: Colors.white, size: 28),
                      ),
                      // Shutter Button
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 28),
                        ),
                      ),
                      const SizedBox(width: 28), // Placeholder for symmetry
                    ],
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
