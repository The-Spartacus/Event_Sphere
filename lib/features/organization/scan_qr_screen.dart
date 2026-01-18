import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


import '../events/data/event_repository.dart';
import '../../core/theme/colors.dart';

class ScanQrScreen extends StatefulWidget {
  final String eventId;

  const ScanQrScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final EventRepository _repository = EventRepository();
  bool _isProcessing = false;
  MobileScannerController cameraController = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ticket'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.torchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                  case TorchState.auto: // Handle auto case if needed, or default
                    return const Icon(Icons.flash_auto, color: Colors.grey);
                  case TorchState.unavailable:
                    return const Icon(Icons.no_flash, color: Colors.grey);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController,
              builder: (context, state, child) {
                switch (state.cameraDirection) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                  case CameraFacing.external:
                    return const Icon(Icons.camera);
                  case CameraFacing.unknown:
                    return const Icon(Icons.device_unknown);
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processCode(barcode.rawValue!);
                  break; // Process only one
                }
              }
            },
          ),
          // Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Align QR Code',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Future<void> _processCode(String code) async {
    setState(() => _isProcessing = true);
    
    try {
      // 1. Fetch Registration Details
      final regDetails = await _repository.getRegistrationDetails(code);

      if (regDetails == null) {
        _showResult(success: false, message: 'Invalid Ticket ID');
        return;
      }

      // 2. Verify Event ID
      final eventId = regDetails['eventId'];
      if (eventId != widget.eventId) {
        _showResult(success: false, message: 'Ticket is for a different event');
        return;
      }

      // 3. Mark Attendance
      final attended = regDetails['attended'] ?? false;
      if (attended) {
        _showResult(success: false, message: 'Already Checked In', isWarning: true);
      } else {
        await _repository.markAttendance(code);
        _showResult(success: true, message: 'Check-in Successful!');
      }

    } catch (e) {
      _showResult(success: false, message: 'Error: ${e.toString()}');
    }
  }

  void _showResult({required bool success, required String message, bool isWarning = false}) {
    // Stop camera temporarily or just show dialog
    // cameraController.stop(); // Optional, but better to keep running but ignore inputs?
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(success ? 'Success' : (isWarning ? 'Warning' : 'Error')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : (isWarning ? Icons.warning : Icons.error),
              color: success ? AppColors.success : (isWarning ? AppColors.warning : AppColors.error),
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
            },
            child: const Text('Scan Next'),
          ),
          if (success)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Exit scanner
              },
              child: const Text('Done'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
