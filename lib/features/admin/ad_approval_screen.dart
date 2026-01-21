import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/auth_service.dart';
import '../events/logic/event_controller.dart';
import '../events/data/event_model.dart';
import '../../core/constants/app_constants.dart';

class AdApprovalScreen extends StatefulWidget {
  const AdApprovalScreen({super.key});

  @override
  State<AdApprovalScreen> createState() => _AdApprovalScreenState();
}

class _AdApprovalScreenState extends State<AdApprovalScreen> {
  bool _isSuperAdmin = false;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      context.read<EventController>().loadPendingAdEvents();
      
      final authService = context.read<AuthService>();
      final uid = authService.currentUserId;
      if (uid != null) {
        final role = await authService.getUserRole(uid);
        if (mounted) {
          setState(() {
            _isSuperAdmin = role == AppConstants.roleSuperAdmin;
            _loadingRole = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingRole = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventController = context.watch<EventController>();
    
    // Use local state instead of authService getter
    final isSuperAdmin = _isSuperAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Ad Requests')),
      body: eventController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : eventController.pendingAdEvents.isEmpty
              ? const Center(child: Text('No pending ad requests'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: eventController.pendingAdEvents.length,
                  itemBuilder: (context, index) {
                    final event = eventController.pendingAdEvents[index];
                    final isGlobalRequest = event.promotionTarget == 'global';
                    final canApprove = isSuperAdmin || (!isGlobalRequest);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: event.posterUrl != null
                                ? Image.network(event.posterUrl!, width: 50, height: 50, fit: BoxFit.cover)
                                : const Icon(Icons.event, size: 50),
                            title: Text(event.title),
                            subtitle: Text('By ${event.organizationName}\nTarget: ${event.promotionTarget.toUpperCase()}'),
                            isThreeLine: true,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _confirmAction(context, event, false),
                                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('REJECT'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: canApprove
                                      ? () => _confirmAction(context, event, true)
                                      : null,
                                  child: Text(canApprove ? 'APPROVE' : 'NEEDS SUPER ADMIN'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _confirmAction(BuildContext context, EventModel event, bool approve) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Ad?' : 'Reject Ad?'),
        content: Text(
          approve
              ? 'This event will be featured as a banner ad for ${event.promotionTarget} audience.'
              : 'The ad request will be rejected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (approve) {
                context.read<EventController>().approveAd(event);
              } else {
                context.read<EventController>().rejectAd(event);
              }
            },
            child: Text(approve ? 'Confirm' : 'Reject', style: TextStyle(color: approve ? Colors.blue : Colors.red)),
          ),
        ],
      ),
    );
  }
}
