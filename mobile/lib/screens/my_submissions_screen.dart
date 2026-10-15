import 'package:flutter/material.dart';
import '../models/water_cooler.dart';
import '../services/api_service.dart';
import '../core/theme.dart';

class MySubmissionsScreen extends StatefulWidget {
  const MySubmissionsScreen({super.key});
  @override
  State<MySubmissionsScreen> createState() => _MySubmissionsScreenState();
}

class _MySubmissionsScreenState extends State<MySubmissionsScreen> {
  final ApiService _api = ApiService();
  List<WaterCooler> _submissions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.fetchMySubmissions();
      setState(() { _submissions = data; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load submissions.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50, // Ultra soft slate-white
      appBar: AppBar(
        title: const Text(
          'My Submissions',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetch,
            tooltip: 'Refresh feed',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.slate600, fontWeight: FontWeight.w600, fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: _fetch,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _submissions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryTint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_location_alt_rounded,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No Submissions Yet',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate800),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Find clean water points in Egypt and report them by long-pressing on the home map view.',
                              style: TextStyle(color: AppColors.slate500, fontSize: 14, height: 1.5),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: _submissions.length,
                      itemBuilder: (_, i) => _SubmissionCard(cooler: _submissions[i]),
                    ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final WaterCooler cooler;
  const _SubmissionCard({required this.cooler});

  @override
  Widget build(BuildContext context) {
    final isRejected = cooler.isRejected;
    final isApproved = cooler.isApproved;

    String statusLabel;
    Color statusColor;
    IconData statusIcon;
    String pointsText = '';
    Color pointsColor = Colors.transparent;

    if (isRejected) {
      statusLabel = 'Rejected';
      statusColor = AppColors.danger; // Slate Red
      statusIcon = Icons.cancel_rounded;
      pointsText = '-100 Trust';
      pointsColor = AppColors.danger;
    } else if (isApproved) {
      statusLabel = 'Approved';
      statusColor = AppColors.success; // Emerald Green
      statusIcon = Icons.check_circle_rounded;
      pointsText = '+50 Trust';
      pointsColor = AppColors.success;
    } else if (cooler.pendingStatus != null) {
      statusLabel = 'Status Pending';
      statusColor = AppColors.info; // Deep Blue
      statusIcon = Icons.swap_horiz_rounded;
    } else {
      statusLabel = 'Under Review';
      statusColor = AppColors.warning; // Amber
      statusIcon = Icons.hourglass_empty_rounded;
    }

    final verified = DateTime.tryParse(cooler.lastVerifiedAt);
    final formattedDate = verified != null
        ? '${verified.year}-${verified.month.toString().padLeft(2, '0')}-${verified.day.toString().padLeft(2, '0')}'
        : cooler.lastVerifiedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.slate200,
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          cooler.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (pointsText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pointsColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: pointsColor.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            pointsText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: pointsColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  if (cooler.pendingStatus != null && !isRejected && !isApproved) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.infoTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.infoDark),
                          const SizedBox(width: 6),
                          Text(
                            'Status Update: Mark as ${cooler.pendingStatus}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.infoDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
