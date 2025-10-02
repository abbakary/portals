import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/session_controller.dart';
import '../data/models.dart';
import '../data/inspections_repository.dart';
import 'controllers/inspector_dashboard_controller.dart';
import 'inspection_form_screen.dart';
import 'inspection_detail_screen.dart';

class InspectorHomeScreen extends StatelessWidget {
  const InspectorHomeScreen({required this.profile, super.key});

  final PortalProfile profile;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InspectorDashboardController>(
      create: (context) => InspectorDashboardController(
        repository: context.read<InspectionsRepository>(),
        sessionController: context.read<SessionController>(),
      )..loadDashboard(),
      child: _InspectorHomeView(profile: profile),
    );
  }
}

class _InspectorHomeView extends StatelessWidget {
  const _InspectorHomeView({required this.profile});

  final PortalProfile profile;

  @override
  Widget build(BuildContext context) {
    return Consumer<InspectorDashboardController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Inspector • ${profile.fullName}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sign out',
                onPressed: () async {
                  await controller.signOut();
                },
              ),
            ],
          ),
          floatingActionButton: controller.vehicles.isEmpty
              ? null
              : FloatingActionButton.extended(
                  icon: const Icon(Icons.add_task),
                  label: const Text('New inspection'),
                  onPressed: () => _startAdHocInspection(context, controller),
                ),
          body: SafeArea(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      children: [
                        if (controller.error != null)
                          Card(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                controller.error ?? '',
                                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                              ),
                            ),
                          ),
                        if (controller.isSyncing)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Syncing offline inspections…'),
                              ],
                            ),
                          ),
                        Text(
                          'Today\'s assignments',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (controller.assignments.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No assignments scheduled.'),
                            ),
                          )
                        else
                          ...controller.assignments.map((assignment) {
                            final vehicle = controller.vehicleById(assignment.vehicleId);
                            return _AssignmentCard(
                              assignment: assignment,
                              vehicle: vehicle,
                              onStart: () => _startAssignmentInspection(context, controller, assignment),
                            );
                          }),
                        const SizedBox(height: 32),
                        Text(
                          'Recent inspections',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (controller.recentInspections.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No inspections submitted yet.'),
                            ),
                          )
                        else
                          ...controller.recentInspections.map(
                            (inspection) => _InspectionListTile(
                              inspection: inspection,
                              onTap: () => _openInspectionDetail(context, inspection),
                            ),
                          ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          icon: const Icon(Icons.sync),
                          label: const Text('Sync offline inspections'),
                          onPressed: controller.isSyncing
                              ? null
                              : () async {
                                  final processed = await controller.syncOfflineInspections();
                                  if (!context.mounted) return;
                                  final message = processed > 0
                                      ? 'Synced $processed inspection(s).'
                                      : 'No inspections waiting for sync.';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                },
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> _startAssignmentInspection(
    BuildContext context,
    InspectorDashboardController controller,
    VehicleAssignmentModel assignment,
  ) async {
    await _openInspectionForm(
      context,
      controller,
      assignment: assignment,
      initialVehicle: controller.vehicleById(assignment.vehicleId),
    );
  }

  Future<void> _startAdHocInspection(
    BuildContext context,
    InspectorDashboardController controller,
  ) async {
    await _openInspectionForm(context, controller);
  }

  Future<void> _openInspectionForm(
    BuildContext context,
    InspectorDashboardController controller, {
    VehicleAssignmentModel? assignment,
    VehicleModel? initialVehicle,
  }) async {
    final inspectorId = controller.inspectorProfileId;
    if (inspectorId == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inspector profile missing'),
          content: const Text('Unable to determine your inspector profile. Please sync assignments or contact an administrator.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }
    if (controller.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checklist categories not available. Try refreshing.')),
      );
      return;
    }
    final draft = await Navigator.of(context).push<InspectionDraftModel>(
      MaterialPageRoute(
        builder: (_) => InspectionFormScreen(
          inspectorId: inspectorId,
          categories: controller.categories,
          vehicles: controller.vehicles,
          assignment: assignment,
          initialVehicle: initialVehicle,
        ),
      ),
    );
    if (draft == null) {
      return;
    }
    final result = await controller.submitInspection(draft);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.isSubmitted
              ? 'Inspection submitted successfully.'
              : 'Inspection saved offline and will sync when online.',
        ),
      ),
    );
  }

  Future<void> _openInspectionDetail(BuildContext context, InspectionSummaryModel summary) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InspectionDetailScreen(summary: summary),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.vehicle,
    required this.onStart,
  });

  final VehicleAssignmentModel assignment;
  final VehicleModel? vehicle;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheduled = DateFormat.yMMMMd().format(assignment.scheduledFor);
    final vehicleLabel = vehicle != null
        ? '${vehicle!.licensePlate} • ${vehicle!.make} ${vehicle!.model}'
        : 'Vehicle #${assignment.vehicleId}';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vehicleLabel, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Scheduled for $scheduled'),
            const SizedBox(height: 4),
            Text('Status: ${assignment.status.replaceAll('_', ' ')}'),
            if (assignment.remarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(assignment.remarks),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.assignment_turned_in),
                label: const Text('Start inspection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectionListTile extends StatelessWidget {
  const _InspectionListTile({required this.inspection, required this.onTap});

  final InspectionSummaryModel inspection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, inspection.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(inspection.vehicle.licensePlate.isNotEmpty
            ? '${inspection.vehicle.licensePlate} • ${inspection.vehicle.make} ${inspection.vehicle.model}'
            : inspection.vehicle.vin),
        subtitle: Text('${inspection.statusDisplay} • ${DateFormat.yMMMd().format(inspection.createdAt)}'),
        trailing: Icon(Icons.chevron_right, color: statusColor),
        onTap: onTap,
      ),
    );
  }

  Color _statusColor(BuildContext context, String status) {
    return switch (status) {
      'submitted' => Colors.deepOrange,
      'approved' => Colors.green,
      'in_progress' => Colors.blue,
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }
}
