import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/water_cooler.dart';
import '../models/sponsor.dart';
import '../services/api_service.dart';
import '../services/api_client.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/photo_pickers.dart';
import '../core/theme.dart';
import 'admin/admin_common.dart';
import 'admin/admin_login_dialog.dart';
import 'admin/create_sponsor_dialog.dart';
import 'admin/current_tab.dart';
import 'admin/dedication_dialog.dart';
import 'admin/pending_tab.dart';
import 'admin/photo_gallery_sheet.dart';
import 'admin/sponsor_assign_sheet.dart';
import 'admin/sponsors_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _authorized = false;

  List<WaterCooler> _pending = [];
  List<WaterCooler> _current = [];
  List<Sponsor> _sponsors = [];
  
  bool _loadingPending = true;
  bool _loadingCurrent = true;
  bool _loadingSponsors = true;
  
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _authorizeAndLoad());
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _query = _searchController.text.trim().toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPending() async {
    if (!_authorized) return;
    setState(() => _loadingPending = true);
    try {
      final result = await _api.fetchPendingCoolers();
      setState(() {
        _pending = result;
        _loadingPending = false;
      });
    } catch (e) {
      setState(() => _loadingPending = false);
      if (_handleAdminAuthError(e)) return;
      _snack('Failed to load pending coolers.', isError: true);
    }
  }

  Future<void> _toggleCups(WaterCooler cooler) async {
    final turnOn = !cooler.cupsEnabled;
    try {
      await _api.setCupsEnabled(cooler.id, turnOn);
      _snack(turnOn
          ? 'Cups are now shown on "${cooler.name}".'
          : 'Cups are now hidden on "${cooler.name}".');
      await _fetchCurrent();
    } catch (e) {
      _snack(friendlyError(e, 'Could not change cups.'), isError: true);
    }
  }

  Future<void> _fetchCurrent() async {
    if (!_authorized) return;
    setState(() => _loadingCurrent = true);
    try {
      final result = await _api.fetchCurrentCoolers();
      setState(() {
        _current = result;
        _loadingCurrent = false;
      });
    } catch (e) {
      setState(() => _loadingCurrent = false);
      if (_handleAdminAuthError(e)) return;
      _snack('Failed to load live coolers.', isError: true);
    }
  }

  Future<void> _fetchSponsors() async {
    if (!_authorized) return;
    setState(() => _loadingSponsors = true);
    try {
      final result = await _api.fetchAllSponsors();
      setState(() {
        _sponsors = result;
        _loadingSponsors = false;
      });
    } catch (e) {
      setState(() => _loadingSponsors = false);
      if (_handleAdminAuthError(e)) return;
      _snack('Failed to load sponsors.', isError: true);
    }
  }

  Future<void> _approve(WaterCooler cooler) async {
    setState(() => _pending.removeWhere((c) => c.id == cooler.id));
    try {
      if (cooler.isApproved) {
        // Already approved cooler, so this must be a photo review card.
        // Approve all unapproved photos for this cooler.
        for (final p in cooler.photos) {
          if (!p.isApproved) {
            await _api.approvePhoto(p.id);
          }
        }
        _snack('✓ Photos for "${cooler.name}" approved.');
      } else {
        await _api.approveCooler(cooler.id);
        _snack('✓ "${cooler.name}" approved.');
      }
      _fetchCurrent();
    } catch (e) {
      if (_handleAdminAuthError(e)) return;
      _snack('Approval failed — refreshing.', isError: true);
      _fetchPending();
    }
  }

  Future<void> _reject(WaterCooler cooler) async {
    setState(() => _pending.removeWhere((c) => c.id == cooler.id));
    try {
      if (cooler.pendingStatus != null) {
        await _api.rejectStatusChange(cooler.id);
        _snack('"${cooler.name}" status update rejected.');
      } else if (cooler.isApproved) {
        // Already approved cooler, so this must be a photo review card.
        // Delete all unapproved photos for this cooler.
        for (final p in cooler.photos) {
          if (!p.isApproved) {
            await _api.deletePhoto(p.id);
          }
        }
        _snack('Photos for "${cooler.name}" rejected.');
      } else {
        await _api.rejectCooler(cooler.id);
        _snack('"${cooler.name}" rejected.');
      }
    } catch (e) {
      if (_handleAdminAuthError(e)) return;
      _snack('Rejection failed — refreshing.', isError: true);
      _fetchPending();
    }
  }

  Future<void> _deleteSpam(WaterCooler cooler) async {
    setState(() => _current.removeWhere((c) => c.id == cooler.id));
    try {
      await _api.deleteCooler(cooler.id);
      _snack('"${cooler.name}" permanently deleted.');
    } catch (e) {
      if (_handleAdminAuthError(e)) return;
      _snack('Delete failed — refreshing.', isError: true);
      _fetchCurrent();
    }
  }

  Future<void> _forceUpdateStatus(WaterCooler cooler, String newStatus) async {
    try {
      await _api.forceUpdateStatus(coolerId: cooler.id, newStatus: newStatus);
      _snack('✓ "${cooler.name}" marked $newStatus.');
      _fetchCurrent();
    } catch (e) {
      if (_handleAdminAuthError(e)) return;
      _snack('Force update failed: $e', isError: true);
    }
  }

  Future<void> _uploadPhotoAdmin(WaterCooler cooler) async {
    final category = await pickPhotoCategory(context);

    if (category == null || !mounted) return;
    
    final source = await pickImageSource(context);
    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
      requestFullMetadata: false,
    );
    if (picked == null) return;

    try {
      await _api.adminUploadPhoto(
        coolerId: cooler.id,
        imageFile: File(picked.path),
        photoCategory: category,
      );
      _snack('Photo uploaded successfully!');
      _fetchCurrent();
    } catch (e) {
      _snack('Failed to upload photo: $e', isError: true);
    }
  }

  Future<void> _showPhotoGallery(BuildContext context, WaterCooler cooler) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminPhotoGallerySheet(cooler: cooler, api: _api),
    );
  }

  Future<void> _showSponsorSheet(BuildContext context, WaterCooler cooler) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminSponsorAssignSheet(
        cooler: cooler,
        api: _api,
        sponsors: _sponsors,
        onAssigned: () {
          _fetchCurrent();
          _snack('✓ Sponsor assigned successfully.');
        },
        onRemoved: () {
          _fetchCurrent();
          _snack('Sponsor association removed.');
        },
      ),
    );
  }


  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    showAppSnackbar(context, message, isError: isError);
  }

  bool _handleAdminAuthError(Object e) {
    if (e.toString().contains('401')) {
      ApiService.clearAdminToken();
      _authorized = false;
      _snack('Admin session expired. Please log in again.', isError: true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _authorizeAndLoad());
      return true;
    }
    return false;
  }

  Future<void> _authorizeAndLoad() async {
    if (!mounted) return;
    final ok = await showAdminLoginDialog(context, _api);
    if (!mounted) return;
    if (!ok) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _authorized = true);
    await _fetchPending();
    await _fetchCurrent();
    await _fetchSponsors();
  }


  List<WaterCooler> get _filteredPending => _query.isEmpty
      ? _pending
      : _pending.where((c) => c.name.toLowerCase().contains(_query)).toList();

  List<WaterCooler> get _filteredCurrent => _query.isEmpty
      ? _current
      : _current.where((c) => c.name.toLowerCase().contains(_query)).toList();

  List<Sponsor> get _filteredSponsors => _query.isEmpty
      ? _sponsors
      : _sponsors.where((s) => s.name.toLowerCase().contains(_query)).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: const Text('Administration Controller',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.domain_add_rounded),
            tooltip: 'Add Sponsor Profile',
            onPressed: () => showCreateSponsorDialog(context,
                api: _api, notify: _snack, onCreated: _fetchSponsors),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Force refresh',
            onPressed: () {
              _fetchPending();
              _fetchCurrent();
              _fetchSponsors();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search reviewers feed…',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.7)),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: Colors.white),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.16),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Review Queue'),
                        if (_pending.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          AdminCountBadge(count: _pending.length),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Live Map'),
                        if (_current.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          AdminCountBadge(
                              count: _current.length,
                              color: AppColors.success),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sponsors'),
                        if (_sponsors.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          AdminCountBadge(
                              count: _sponsors.length,
                              color: AppColors.info),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AdminPendingTab(
            loading: _loadingPending,
            coolers: _filteredPending,
            onApprove: _approve,
            onReject: _reject,
            onViewPhotos: (c) => _showPhotoGallery(context, c),
          ),
          AdminCurrentTab(
            loading: _loadingCurrent,
            coolers: _filteredCurrent,
            onDelete: _deleteSpam,
            onForceStatus: _forceUpdateStatus,
            onAddPhoto: _uploadPhotoAdmin,
            onViewPhotos: (c) => _showPhotoGallery(context, c),
            onManageSponsor: (c) => _showSponsorSheet(context, c),
            onToggleCups: _toggleCups,
            onDedicate: (c) => showDedicationDialog(
              context,
              cooler: c,
              api: _api,
              notify: _snack,
              onChanged: _fetchCurrent,
            ),
          ),
          AdminSponsorsTab(
            loading: _loadingSponsors,
            sponsors: _filteredSponsors,
            api: _api,
            onRefresh: _fetchSponsors,
            snack: _snack,
          ),
        ],
      ),
    );
  }
}

