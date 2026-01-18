import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../events/data/event_model.dart';
import '../../events/data/event_repository.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/theme/colors.dart';
import '../../../app/app_config.dart';

class TicketScreen extends StatefulWidget {
  final EventModel event;

  const TicketScreen({
    super.key,
    required this.event,
  });

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final EventRepository _repository = EventRepository();
  String? _registrationId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRegistration();
  }

  Future<void> _loadRegistration() async {
    final authService = context.read<AuthService>();
    final userId = authService.currentUserId;

    if (userId == null) {
      setState(() {
        _error = 'User not logged in';
        _isLoading = false;
      });
      return;
    }

    try {
      final regId = await _repository.getRegistrationId(userId, widget.event.id);
      if (mounted) {
        setState(() {
          _registrationId = regId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load ticket';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Dark background for ticket pop
      appBar: AppBar(
        title: const Text('My Ticket'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.white))
                : _registrationId == null
                    ? const Text('Ticket not found', style: TextStyle(color: Colors.white))
                    : _buildTicketCard(),
      ),
    );
  }

  Widget _buildTicketCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Event Title
          Text(
            widget.event.title,
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.event.organizationName,
            style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // QR Code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: _registrationId!,
              version: QrVersions.auto,
              size: 200.0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scan this code at the venue',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 24),
          
          Divider(color: Colors.grey[300], thickness: 1, height: 32),

          // Ticket Details
          _TicketDetailRow(label: 'Date', value: '${widget.event.date.day}/${widget.event.date.month}/${widget.event.date.year}'),
          _TicketDetailRow(label: 'Time', value: '${TimeOfDay.fromDateTime(widget.event.startTime).format(context)}'),
          _TicketDetailRow(label: 'Venue', value: widget.event.location),
          _TicketDetailRow(label: 'Ticket ID', value: _registrationId!.substring(0, 8).toUpperCase()),
        ],
      ),
    );
  }
}

class _TicketDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _TicketDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(color: Colors.grey)),
          Text(value, style: AppTextStyles.bodyBold.copyWith(color: Colors.black)),
        ],
      ),
    );
  }
}
