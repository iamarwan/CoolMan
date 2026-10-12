part of 'admin_screen.dart';

class _SponsorsTab extends StatelessWidget {
  final bool loading;
  final List<Sponsor> sponsors;
  final ApiService api;
  final VoidCallback onRefresh;
  final void Function(String message, {bool isError}) snack;

  const _SponsorsTab({
    required this.loading,
    required this.sponsors,
    required this.api,
    required this.onRefresh,
    required this.snack,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _Loader();

    if (sponsors.isEmpty) {
      return const _EmptyState(
        icon: Icons.volunteer_activism_outlined,
        title: 'Sponsor list is empty',
        subtitle: 'Incentivize local mosques and shops, then add profiles.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sponsors.length,
      itemBuilder: (ctx, i) {
        final sponsor = sponsors[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sponsor.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                          const SizedBox(height: 4),
                          Text('${sponsor.sponsorType} · ${sponsor.coolerCount} Coolers Maintained',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    if (sponsor.verified)
                      const Icon(Icons.verified_rounded, color: Color(0xFF10B981))
                  ],
                ),
                if (sponsor.contact != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.link, size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Text(sponsor.contact!, style: const TextStyle(color: Color(0xFF334155), fontSize: 13)),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!sponsor.verified)
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await api.verifySponsor(sponsor.id);
                            snack('Sponsor profile verified.');
                            onRefresh();
                          } catch (e) {
                            snack('Verification failed: $e', isError: true);
                          }
                        },
                        icon: const Icon(Icons.verified_rounded, size: 16),
                        label: const Text('Verify'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10B981),
                            side: const BorderSide(color: Color(0xFF10B981)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await api.deleteSponsor(sponsor.id);
                          snack('Sponsor profile deleted successfully.');
                          onRefresh();
                        } catch (e) {
                          snack('Deletion failed: $e', isError: true);
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PhotoGallerySheet extends StatefulWidget {
  final WaterCooler cooler;
  final ApiService api;

  const _PhotoGallerySheet({required this.cooler, required this.api});

  @override
  State<_PhotoGallerySheet> createState() => _PhotoGallerySheetState();
}

class _PhotoGallerySheetState extends State<_PhotoGallerySheet> {
  static const _base = 'http://10.0.2.2:8000';
  List<CoolerPhoto> _photos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final photos = await widget.api.fetchCoolerPhotosAdmin(widget.cooler.id);
      setState(() {
        _photos = photos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load photos.';
        _loading = false;
      });
    }
  }

  Future<void> _approvePhoto(CoolerPhoto photo) async {
    try {
      await widget.api.approvePhoto(photo.id);
      setState(() {
        final idx = _photos.indexWhere((p) => p.id == photo.id);
        if (idx != -1) {
          _photos[idx] = CoolerPhoto(
            id: photo.id,
            coolerId: photo.coolerId,
            filePath: photo.filePath,
            uploadedAt: photo.uploadedAt,
            isApproved: true,
          );
        }
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Approval failed.'),
              backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  Future<void> _deletePhoto(CoolerPhoto photo) async {
    try {
      await widget.api.deletePhoto(photo.id);
      setState(() => _photos.removeWhere((p) => p.id == photo.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Delete failed.'),
              backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  void _openFullscreen(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF0F766E), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.cooler.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_loading && _photos.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F1F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_photos.length} item${_photos.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0F766E),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF0F766E))),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 14)),
                          ],
                        ),
                      )
                    : _photos.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(60),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No user submitted photos.',
                                  style: TextStyle(
                                      color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1,
                            ),
                            itemCount: _photos.length,
                            itemBuilder: (_, i) {
                              final photo = _photos[i];
                              final url = '$_base${photo.filePath}';
                              return GestureDetector(
                                onTap: () => _openFullscreen(context, url),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(14)),
                                          child: Icon(
                                              Icons.broken_image_outlined,
                                              color: Colors.grey.shade400,
                                              size: 36),
                                        ),
                                        loadingBuilder: (_, child, progress) =>
                                            progress == null
                                                ? child
                                                : Container(
                                                    decoration: BoxDecoration(
                                                        color: Colors.grey.shade500,
                                                        borderRadius:
                                                            BorderRadius.circular(14)),
                                                    child: const Center(
                                                        child: CircularProgressIndicator(
                                                            strokeWidth: 2, color: Colors.white)),
                                                  ),
                                      ),
                                    ),
                                    if (photo.isApproved)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.white,
                                                  width: 1.5)),
                                          child: const Icon(Icons.check_rounded,
                                              color: Colors.white, size: 10),
                                        ),
                                      ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  bottom: Radius.circular(14)),
                                          color: Colors.black.withValues(alpha: 0.65),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            if (!photo.isApproved)
                                              GestureDetector(
                                                onTap: () =>
                                                    _approvePhoto(photo),
                                                child: const Icon(
                                                    Icons.check_circle_outline,
                                                    color: Color(0xFF34D399),
                                                    size: 22),
                                              ),
                                            GestureDetector(
                                              onTap: () => _deletePhoto(photo),
                                              child: const Icon(
                                                  Icons.delete_outline,
                                                  color: Color(0xFFF87171),
                                                  size: 22),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SponsorAssignSheet extends StatefulWidget {
  final WaterCooler cooler;
  final ApiService api;
  final List<Sponsor> sponsors;
  final VoidCallback onAssigned;
  final VoidCallback onRemoved;

  const _SponsorAssignSheet({
    required this.cooler,
    required this.api,
    required this.sponsors,
    required this.onAssigned,
    required this.onRemoved,
  });

  @override
  State<_SponsorAssignSheet> createState() => _SponsorAssignSheetState();
}

class _SponsorAssignSheetState extends State<_SponsorAssignSheet> {
  bool _loading = false;
  String? _error;

  Future<void> _removeSponsor() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.api.removeSponsor(widget.cooler.id);
      widget.onRemoved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to remove sponsor association.';
      });
    }
  }

  Future<void> _assign(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.api.assignSponsor(coolerId: widget.cooler.id, sponsorId: id);
      widget.onAssigned();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Failed to assign sponsor.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sponsor = widget.cooler.sponsor;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.volunteer_activism_outlined,
                    color: Color(0xFF0F766E), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sponsor != null
                        ? 'Manage sponsor association'
                        : 'Assign sponsor',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sponsor != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F1F0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.volunteer_activism_rounded,
                              color: Color(0xFF0F766E)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              sponsor.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sponsor represents verified status sadaka. Removing Association will orphan this cooler.',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                    ),
                    const Spacer(),
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton(
                      onPressed: _loading ? null : _removeSponsor,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _loading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Remove Assigned Sponsor', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    const Text(
                      'Select sponsor profile from records:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: widget.sponsors.isEmpty
                          ? const Center(child: Text('Create a sponsor first in the Sponsors tab.'))
                          : ListView.builder(
                              itemCount: widget.sponsors.length,
                              itemBuilder: (ctx, i) {
                                final s = widget.sponsors[i];
                                return ListTile(
                                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text(s.sponsorType, style: const TextStyle(fontSize: 11)),
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                                  onTap: () => _assign(s.id),
                                );
                              },
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PendingTab extends StatelessWidget {
  final bool loading;
  final List<WaterCooler> coolers;
  final void Function(WaterCooler) onApprove;
  final void Function(WaterCooler) onReject;
  final void Function(WaterCooler) onViewPhotos;

  const _PendingTab({
    required this.loading,
    required this.coolers,
    required this.onApprove,
    required this.onReject,
    required this.onViewPhotos,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _Loader();

    if (coolers.isEmpty) {
      return const _EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'Review Queue Clear',
        subtitle: 'All newly proposed water coolers resolved.',
      );
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFE2F1F0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: const Row(
            children: [
              Icon(Icons.swipe_rounded, size: 14, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Text(
                'Swipe right to approve · Swipe left to reject',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: coolers.length,
            itemBuilder: (_, i) => _SwipeablePendingCard(
              key: ValueKey(coolers[i].id),
              cooler: coolers[i],
              onApprove: () => onApprove(coolers[i]),
              onReject: () => onReject(coolers[i]),
              onViewPhotos: () => onViewPhotos(coolers[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwipeablePendingCard extends StatelessWidget {
  final WaterCooler cooler;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewPhotos;

  const _SwipeablePendingCard({
    super.key,
    required this.cooler,
    required this.onApprove,
    required this.onReject,
    required this.onViewPhotos,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(cooler.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onApprove();
          return true;
        } else {
          onReject();
          return true;
        }
      },
      background: const _SwipeBg(
        color: Color(0xFF10B981),
        icon: Icons.check_circle_rounded,
        label: 'Approve',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const _SwipeBg(
        color: Color(0xFFEF4444),
        icon: Icons.cancel_rounded,
        label: 'Reject',
        alignment: Alignment.centerRight,
      ),
      child: _PendingCard(
        cooler: cooler,
        onApprove: onApprove,
        onReject: onReject,
        onViewPhotos: onViewPhotos,
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  const _SwipeBg({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = alignment == Alignment.centerLeft;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeft
            ? [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ]
            : [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 24),
              ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final WaterCooler cooler;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewPhotos;

  const _PendingCard({
    required this.cooler,
    required this.onApprove,
    required this.onReject,
    required this.onViewPhotos,
  });

  bool get _isStatusUpdate => cooler.pendingStatus != null;
  bool get _isNewProposal => !cooler.isApproved;

  Color get _typeColor {
    if (_isStatusUpdate) return const Color(0xFFF59E0B);
    if (_isNewProposal) return const Color(0xFF4F46E5);
    return const Color(0xFF0F766E);
  }

  IconData get _typeIcon {
    if (_isStatusUpdate) return Icons.swap_horiz_rounded;
    if (_isNewProposal) return Icons.add_location_alt_rounded;
    return Icons.image_search_rounded;
  }

  String get _typeLabel {
    if (_isStatusUpdate) return 'Status Update Review';
    if (_isNewProposal) return 'New Location Proposal';
    return 'New Photo Submission';
  }

  @override
  Widget build(BuildContext context) {
    final verified = DateTime.tryParse(cooler.lastVerifiedAt);

    final formattedDate = verified != null
        ? '${verified.year}-${verified.month.toString().padLeft(2, '0')}-${verified.day.toString().padLeft(2, '0')} '
            '${verified.hour.toString().padLeft(2, '0')}:${verified.minute.toString().padLeft(2, '0')}'
        : cooler.lastVerifiedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(_typeIcon, size: 14, color: _typeColor),
                const SizedBox(width: 8),
                Text(
                  _typeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _typeColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cooler.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 12),
                _AdminMetaRow(
                  icon: Icons.location_on_outlined,
                  text:
                      'GPS: ${cooler.latitude.toStringAsFixed(6)}, ${cooler.longitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 6),
                _AdminMetaRow(
                  icon: Icons.access_time_rounded,
                  text: 'Submitted: $formattedDate',
                ),
                if (_isStatusUpdate) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StatusPill(
                          label: cooler.status,
                          color: _statusColor(cooler.status)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 16, color: Colors.grey),
                      ),
                      _StatusPill(
                        label: cooler.pendingStatus!,
                        color: _statusColor(cooler.pendingStatus!),
                        isPending: true,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: onViewPhotos,
                  icon: const Icon(Icons.photo_library_outlined, size: 15),
                  label: Text(
                    cooler.photos.isEmpty
                        ? 'No user photos'
                        : 'View ${cooler.photos.length} item${cooler.photos.length == 1 ? '' : 's'}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F766E),
                    side: BorderSide(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: BorderSide(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentTab extends StatelessWidget {
  final bool loading;
  final List<WaterCooler> coolers;
  final void Function(WaterCooler) onDelete;
  final void Function(WaterCooler, String) onForceStatus;
  final void Function(WaterCooler) onAddPhoto;
  final void Function(WaterCooler) onViewPhotos;
  final void Function(WaterCooler) onManageSponsor;

  const _CurrentTab({
    required this.loading,
    required this.coolers,
    required this.onDelete,
    required this.onForceStatus,
    required this.onAddPhoto,
    required this.onViewPhotos,
    required this.onManageSponsor,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _Loader();

    if (coolers.isEmpty) {
      return const _EmptyState(
        icon: Icons.water_drop_outlined,
        title: 'Map Index empty',
        subtitle: 'Once approved, coolers will populate here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: coolers.length,
      itemBuilder: (_, i) => _LiveCard(
        cooler: coolers[i],
        onDelete: () => onDelete(coolers[i]),
        onForceStatus: (s) => onForceStatus(coolers[i], s),
        onAddPhoto: () => onAddPhoto(coolers[i]),
        onViewPhotos: () => onViewPhotos(coolers[i]),
        onManageSponsor: () => onManageSponsor(coolers[i]),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final WaterCooler cooler;
  final VoidCallback onDelete;
  final void Function(String) onForceStatus;
  final VoidCallback onAddPhoto;
  final VoidCallback onViewPhotos;
  final VoidCallback onManageSponsor;

  const _LiveCard({
    required this.cooler,
    required this.onDelete,
    required this.onForceStatus,
    required this.onAddPhoto,
    required this.onViewPhotos,
    required this.onManageSponsor,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(cooler.status);
    final verified = DateTime.tryParse(cooler.lastVerifiedAt);

    final formattedDate = verified != null
        ? '${verified.year}-${verified.month.toString().padLeft(2, '0')}-${verified.day.toString().padLeft(2, '0')}'
        : cooler.lastVerifiedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(_statusIcon(cooler.status), color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cooler.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                              child:
                                  _StatusPill(label: cooler.status, color: color)),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today_outlined,
                              size: 11, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              formattedDate,
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onAddPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  color: const Color(0xFF3B82F6),
                  tooltip: 'Admin Add Photo',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                IconButton(
                  onPressed: onViewPhotos,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.photo_library_outlined),
                      if (cooler.photos.isNotEmpty)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Color(0xFF0F766E), shape: BoxShape.circle),
                            child: Text(
                              '${cooler.photos.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  color: const Color(0xFF0F766E),
                  tooltip: 'Inspect Gallery',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFE2F1F0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFEF4444),
                  tooltip: 'Spam cleanup',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Color(0xFF94A3B8)),
                  tooltip: 'Audit status options',
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  onSelected: (value) {
                    if (value == '__sponsor__') {
                      onManageSponsor();
                    } else {
                      onForceStatus(value);
                    }
                  },
                  itemBuilder: (_) => [
                    _forceMenuItem('Working', const Color(0xFF10B981), Icons.water_drop),
                    _forceMenuItem(
                        'Empty', const Color(0xFF64748B), Icons.water_drop_outlined),
                    _forceMenuItem('Broken', const Color(0xFFEF4444), Icons.report),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: '__sponsor__',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE2F1F0),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.volunteer_activism_outlined,
                                color: Color(0xFF0F766E),
                                size: 16),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            cooler.sponsor != null
                                ? 'Edit sponsor mapping'
                                : 'Map Sponsor',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F766E),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (cooler.sponsor != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.volunteer_activism_rounded,
                        color: Color(0xFF16A34A), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Sponsored Sadie: ${cooler.sponsor!.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cooler.sponsor!.verified)
                      const Icon(Icons.verified_rounded,
                          size: 14, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _forceMenuItem(
      String status, Color color, IconData icon) {
    return PopupMenuItem<String>(
      value: status,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text('Verify $status',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

Color _statusColor(String status) => switch (status) {
      'Working' => const Color(0xFF10B981),
      'Empty' => const Color(0xFF64748B),
      'Broken' => const Color(0xFFEF4444),
      _ => Colors.blue,
    };

IconData _statusIcon(String status) => switch (status) {
      'Working' => Icons.water_drop,
      'Empty' => Icons.water_drop_outlined,
      'Broken' => Icons.report,
      _ => Icons.help_outline,
    };

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isPending;

  const _StatusPill({
    required this.label,
    required this.color,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isPending ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isPending ? 0.6 : 0.3),
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _AdminMetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AdminMetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color? color;

  const _CountBadge({required this.count, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFF59E0B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$count',
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: const Color(0xFF0F766E).withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
