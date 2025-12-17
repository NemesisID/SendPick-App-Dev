import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'delivery_proof_form_screen.dart';
import '../models/order.dart';

class ScanScreen extends StatefulWidget {
  final VoidCallback? onBackTap;
  final Order? currentOrder;
  final List<Order>? availableOrders;
  final Function(String orderId)? onOrderCompleted;

  const ScanScreen({
    super.key, 
    this.onBackTap,
    this.currentOrder,
    this.availableOrders,
    this.onOrderCompleted,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isFlashOn = false;
  int _selectedCameraIndex = 0;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _startCamera(_selectedCameraIndex);
      }
    } catch (e) {
      debugPrint('Error getting cameras: $e');
    }
  }

  void _startCamera(int cameraIndex) {
    if (_cameras.isEmpty) return;

    final camera = _cameras[cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });
    _startCamera(_selectedCameraIndex);
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      
      if (!mounted) return;
      
      // Navigate to delivery proof form with order data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryProofFormScreen(
            imagePath: image.path,
            order: widget.currentOrder,
            availableOrders: widget.availableOrders,
            onOrderCompleted: widget.onOrderCompleted,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null && mounted) {
        // Navigate to delivery proof form with order data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryProofFormScreen(
              imagePath: image.path,
              order: widget.currentOrder,
              availableOrders: widget.availableOrders,
              onOrderCompleted: widget.onOrderCompleted,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // 0. Camera Preview Layer
            if (_controller != null && _controller!.value.isInitialized)
              SizedBox.expand(
                child: CameraPreview(_controller!),
              )
            else
              const Center(child: CircularProgressIndicator(color: Colors.white)),

            // 1. Header (Back Button & Title)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onBackTap ?? () {},
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Text(
                    'Scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 24), // Balance the row
                ],
              ),
            ),

            // 2. Center Scanner Overlay (Brackets only, no line)
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: AspectRatio(
                  aspectRatio: 16 / 9, // Match POD preview aspect ratio
                  child: CustomPaint(
                    painter: ScannerOverlayPainter(),
                  ),
                ),
              ),
            ),

            // 3. Flash Icon
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

            // 4. Bottom Controls
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
                        onTap: _pickImageFromGallery,
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.image_outlined,
                              color: Colors.white, size: 28),
                        ),
                      ),

                      // Shutter Button (Camera)
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE0E0E0),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.black, size: 28),
                            ),
                          ),
                        ),
                      ),

                      // Switch Camera Button
                      GestureDetector(
                        onTap: _switchCamera,
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cached,
                              color: Colors.white, size: 28),
                        ),
                      ),
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

// Custom Painter for the brackets and line
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double cornerLength = 40;
    double radius = 20;

    // Top Left
    Path topLeft = Path();
    topLeft.moveTo(0, cornerLength);
    topLeft.lineTo(0, radius);
    topLeft.arcToPoint(Offset(radius, 0), radius: Radius.circular(radius));
    topLeft.lineTo(cornerLength, 0);
    canvas.drawPath(topLeft, paint);

    // Top Right
    Path topRight = Path();
    topRight.moveTo(size.width - cornerLength, 0);
    topRight.lineTo(size.width - radius, 0);
    topRight.arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius));
    topRight.lineTo(size.width, cornerLength);
    canvas.drawPath(topRight, paint);

    // Bottom Left
    Path bottomLeft = Path();
    bottomLeft.moveTo(0, size.height - cornerLength);
    bottomLeft.lineTo(0, size.height - radius);
    bottomLeft.arcToPoint(Offset(radius, size.height), radius: Radius.circular(radius), clockwise: false);
    bottomLeft.lineTo(cornerLength, size.height);
    canvas.drawPath(bottomLeft, paint);

    // Bottom Right
    Path bottomRight = Path();
    bottomRight.moveTo(size.width - cornerLength, size.height);
    bottomRight.lineTo(size.width - radius, size.height);
    bottomRight.arcToPoint(Offset(size.width, size.height - radius), radius: Radius.circular(radius), clockwise: false);
    bottomRight.lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(bottomRight, paint);
    // Center line removed
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
