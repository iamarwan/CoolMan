import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/water_cooler.dart';
import '../services/api_service.dart';
part 'admin_widgets.dart';

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
    final category = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'What are you photographing?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.water_drop_outlined, color: Color(0xFF0F766E)),
                title: const Text('The Cooler'),
                subtitle: const Text('Overall view of the unit'),
                onTap: () => Navigator.pop(ctx, 'Cooler'),
              ),
              ListTile(
                leading: const Icon(Icons.coffee_outlined, color: Color(0xFF0F766E)),
                title: const Text('The Cups'),
                subtitle: const Text('Cup availability and condition'),
                onTap: () => Navigator.pop(ctx, 'Cups'),
              ),
            ],
          ),
        ),
      ),
    );

    if (category == null || !mounted) return;
    
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0F766E)),
                title: const Text('Take dynamic photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library_outlined, color: Color(0xFF0F766E)),
                title: const Text('Select from Local Album'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
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
      builder: (_) => _PhotoGallerySheet(cooler: cooler, api: _api),
    );
  }

  Future<void> _showSponsorSheet(BuildContext context, WaterCooler cooler) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SponsorAssignSheet(
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

  Future<void> _showCreateSponsorDialog() async {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();

    String selectedType = 'Business';
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Create New Sponsor',
              style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sponsor Entity Name', border: OutlineInputBorder()),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                  enabled: !loading,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                      labelText: 'Sponsor Category', border: OutlineInputBorder()),
                  items: ['Business', 'Mosque', 'Individual', 'NGO']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: loading
                      ? null
                      : (v) => setDialog(() => selectedType = v!),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Contact Information',
                      border: OutlineInputBorder()),
                  enabled: !loading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialog(() => loading = true);
                      try {
                        await _api.createSponsor(
                          name: nameCtrl.text.trim(),
                          sponsorType: selectedType,
                          contact: contactCtrl.text.trim().isEmpty
                              ? null
                              : contactCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _snack('✓ Sponsor successfully created.');
                        _fetchSponsors(); 
                      } catch (e) {
                        setDialog(() => loading = false);
                        _snack('Failed to create sponsor: $e', isError: true);
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    contactCtrl.dispose();
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
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
    final ok = await _showAdminLoginDialog();
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

  Future<bool> _showAdminLoginDialog() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool loading = false;
    String? error;

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Verify Administrative Account'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Admin Username', border: OutlineInputBorder()),
                enabled: !loading,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
                enabled: !loading,
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.of(ctx).pop(false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      final user = usernameController.text.trim();
                      final pass = passwordController;
                      if (user.isEmpty || pass.text.isEmpty) {
                        setDialog(() => error = 'Credentials required.');
                        return;
                      }
                      setDialog(() {
                        loading = true;
                        error = null;
                      });
                      try {
                        await _api.adminLogin(username: user, password: pass.text);
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (_) {
                        setDialog(() {
                          loading = false;
                          error = 'Invalid administrative credentials.';
                        });
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Authenticate'),
            ),
          ],
        ),
      ),
    );

    usernameController.dispose();
    passwordController.dispose();
    return success == true;
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Administration Controller',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.domain_add_rounded),
            tooltip: 'Add Sponsor Profile',
            onPressed: _showCreateSponsorDialog,
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
                          _CountBadge(count: _pending.length),
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
                          _CountBadge(
                              count: _current.length,
                              color: const Color(0xFF10B981)),
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
                          _CountBadge(
                              count: _sponsors.length,
                              color: const Color(0xFF3B82F6)),
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
          _PendingTab(
            loading: _loadingPending,
            coolers: _filteredPending,
            onApprove: _approve,
            onReject: _reject,
            onViewPhotos: (c) => _showPhotoGallery(context, c),
          ),
          _CurrentTab(
            loading: _loadingCurrent,
            coolers: _filteredCurrent,
            onDelete: _deleteSpam,
            onForceStatus: _forceUpdateStatus,
            onAddPhoto: _uploadPhotoAdmin,
            onViewPhotos: (c) => _showPhotoGallery(context, c),
            onManageSponsor: (c) => _showSponsorSheet(context, c),
          ),
          _SponsorsTab(
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

