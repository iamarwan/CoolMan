import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../models/water_cooler.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/photo_pickers.dart';
import '../widgets/status_style.dart';
import 'admin_screen.dart';
import 'profile_screen.dart';
import 'sponsor_screen.dart';
import '../core/theme.dart';

class _PhotoDraft {
  final XFile file;
  final String category;
  _PhotoDraft(this.file, this.category);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _fallback = LatLng(29.9600, 31.2500); // Cairo default
  final MapController _mapController = MapController();
  final ApiService _api = ApiService();
  final LocationService _location = LocationService();
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final PopupController _popupController = PopupController();

  List<WaterCooler> _coolers = [];
  List<WaterCooler> _searchResults = [];
  LatLng? _userLocation;
  bool _loading = true;
  bool _searchMode = false;
  bool _searching = false;
  bool _showSearchList = false;
  int _titleTapCount = 0;
  DateTime? _firstTapTime;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initLocation();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _searchMode) _runSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleTitleTap() {
    final now = DateTime.now();
    if (_firstTapTime == null ||
        now.difference(_firstTapTime!) > const Duration(seconds: 3)) {
      _firstTapTime = now;
      _titleTapCount = 1;
    } else {
      _titleTapCount++;
    }
    if (_titleTapCount >= 5) {
      _titleTapCount = 0;
      _firstTapTime = null;
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AdminScreen()));
    }
  }

  Future<void> _initLocation() async {
    final loc = await _resolveLocation();
    setState(() => _userLocation = loc);
    await _fetchCoolers();
  }

  Future<LatLng> _resolveLocation() async {
    try {
      final position = await _location.resolveCurrentPosition();
      if (position != null) return LatLng(position.latitude, position.longitude);
    } on LocationServiceDisabledException catch (e) {
      _showSnackbar(e.message, isError: true);
    } on LocationPermissionDeniedException catch (e) {
      _showSnackbar(e.message, isError: true);
    } on LocationPermissionPermanentlyDeniedException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (e) {
      _showSnackbar('Could not get location: $e', isError: true);
    }
    return _fallback;
  }

  Future<void> _fetchCoolers() async {
    final loc = _userLocation ?? _fallback;
    setState(() => _loading = true);
    try {
      final coolers = await _api.fetchNearbyCoolers(
          lat: loc.latitude, lng: loc.longitude);
      setState(() {
        _coolers = coolers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnackbar('Failed to load coolers: $e', isError: true);
    }
  }

  Future<void> _recenterOnUser() async {
    final loc = await _resolveLocation();
    setState(() => _userLocation = loc);
    _mapController.move(loc, 14.5);
    await _fetchCoolers();
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchList = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await _api.searchCoolers(query);
      setState(() {
        _searchResults = results;
        _searching = false;
        _showSearchList = results.isNotEmpty;
      });
      if (results.isNotEmpty) {
        _mapController.move(
            LatLng(results.first.latitude, results.first.longitude), 15.0);
      }
    } catch (e) {
      setState(() => _searching = false);
      _showSnackbar('Search failed: $e', isError: true);
    }
  }

  Future<bool> _ensureLoggedIn() async {
    if (ApiService.isLoggedIn) return true;
    return await _showAuthDialog();
  }

  Future<bool> _showAuthDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _AuthDialog(),
    );
    if (result == true) setState(() {});
    return result == true;
  }

  Future<void> _onMapLongPress(LatLng point) async {
    final ok = await _ensureLoggedIn();
    if (!ok || !mounted) return;
    _showAddCoolerDialog(point);
  }

  Future<void> _createCoolerWithPhotos(
    String name,
    LatLng point,
    List<_PhotoDraft> photos, {
    bool? hasCups,
    String? cupsType,
  }) async {
    try {
      final created = await _api.createCoolerAndReturnId(
        name: name,
        latitude: point.latitude,
        longitude: point.longitude,
        hasCups: hasCups,
        cupsType: cupsType,
      );
      
      for (final p in photos) {
        try {
          await _api.uploadPhoto(
            coolerId: created,
            imageFile: File(p.file.path),
            photoCategory: p.category,
          );
        } catch (_) {}
      }
      _showSnackbar('Cooler submitted successfully! +50 Trust pending.');
      await _fetchCoolers();
    } catch (e) {
      _showSnackbar('$e', isError: true);
    }
  }

  Future<void> _updateCoolerStatus(
      WaterCooler cooler, String newStatus) async {
    final ok = await _ensureLoggedIn();
    if (!ok || !mounted) return;
    try {
      await _api.updateCoolerStatus(
          coolerId: cooler.id, newStatus: newStatus);
      if (mounted) Navigator.of(context).pop();
      _showSnackbar('Status updated! Confirmed report earns points.');
      await _fetchCoolers();
    } catch (e) {
      _showSnackbar('Failed to update status: $e', isError: true);
    }
  }

  Future<void> _confirmWorking(WaterCooler cooler) async {
    try {
      final result = await _api.confirmCoolerWorking(cooler.id);
      final newScore = result['trust_score'] as int?;
      if (mounted) Navigator.of(context).pop();
      _showSnackbar(
        newScore != null
            ? '✓ Verified! +5 Points (Balance: $newScore pts)'
            : '✓ Verified working!',
      );
      await _fetchCoolers();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showSnackbar(msg, isError: true);
    }
  }

  Future<void> _uploadPhoto(WaterCooler cooler) async {
    final ok = await _ensureLoggedIn();
    if (!ok || !mounted) return;

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
      await _api.uploadPhoto(
        coolerId: cooler.id,
        imageFile: File(picked.path),
        photoCategory: category,
      );
      _showSnackbar('Verification photo attached successfully!');
    } catch (e) {
      _showSnackbar('Failed to upload photo: $e', isError: true);
    }
  }

  Future<void> _showAddCoolerDialog(LatLng point) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<_PhotoDraft> pickedPhotos = [];
    String pickedCategory = 'Cooler';
    bool? hasCups;
    String? cupsType;
    
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Add Public Cooler Point', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Label Name / Landmark',
                        hintText: 'e.g. Next to El-Tawheed Mosque',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (value.trim().length > 255) return 'Length limited to 255 chars';
                        return null;
                      },
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Does it have clean cups?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate800),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _CupsToggleChip(
                          label: 'Yes',
                          icon: Icons.coffee_rounded,
                          color: AppColors.success,
                          selected: hasCups == true,
                          onTap: () => setDialog(() {
                            hasCups = true;
                          }),
                        ),
                        const SizedBox(width: 8),
                        _CupsToggleChip(
                          label: 'No',
                          icon: Icons.coffee_outlined,
                          color: AppColors.danger,
                          selected: hasCups == false,
                          onTap: () => setDialog(() {
                            hasCups = false;
                            cupsType = null;
                          }),
                        ),
                        const SizedBox(width: 8),
                        _CupsToggleChip(
                          label: 'Unsure',
                          icon: Icons.help_outline_rounded,
                          color: AppColors.slate500,
                          selected: hasCups == null,
                          onTap: () => setDialog(() {
                            hasCups = null;
                            cupsType = null;
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Text(
                      'Attach verification photos (Recommended)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate800),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _PhotoCategoryChip(
                            label: 'Cooler Unit',
                            icon: Icons.water_drop_outlined,
                            selected: pickedCategory == 'Cooler',
                            onTap: () => setDialog(() => pickedCategory = 'Cooler'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PhotoCategoryChip(
                            label: 'Cups Rack',
                            icon: Icons.coffee_outlined,
                            selected: pickedCategory == 'Cups',
                            onTap: () => setDialog(() => pickedCategory = 'Cups'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final x = await _imagePicker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1920,
                                imageQuality: 85,
                                requestFullMetadata: false,
                              );
                              if (x != null) setDialog(() => pickedPhotos.add(_PhotoDraft(x, pickedCategory)));
                            },
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            label: const Text('Galleries'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final x = await _imagePicker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 1920,
                                imageQuality: 85,
                                requestFullMetadata: false,
                              );
                              if (x != null) setDialog(() => pickedPhotos.add(_PhotoDraft(x, pickedCategory)));
                            },
                            icon: const Icon(Icons.camera_alt_outlined, size: 18),
                            label: const Text('Camera'),
                          ),
                        ),
                      ],
                    ),
                    if (pickedPhotos.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: pickedPhotos.length,
                          itemBuilder: (ctx, i) {
                            final p = pickedPhotos[i];
                            return Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(p.file.path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 14,
                                  child: GestureDetector(
                                    onTap: () => setDialog(() => pickedPhotos.removeAt(i)),
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: AppColors.danger,
                                      child: Icon(Icons.close_rounded, size: 13, color: Colors.white),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p.category,
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final photos = List<_PhotoDraft>.from(pickedPhotos);
                  Navigator.of(ctx).pop();
                  _createCoolerWithPhotos(
                    controller.text.trim(),
                    point,
                    photos,
                    hasCups: hasCups,
                    cupsType: cupsType,
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Propose Location'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchDirections(WaterCooler cooler) async {
    final lat = cooler.latitude;
    final lng = cooler.longitude;
    final androidUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking';
    final iosUrl = 'maps://?daddr=$lat,$lng&dirflg=w';
    final fallbackUrl =
        'https://www.openstreetmap.org/directions?from=&to=$lat,$lng';
    final uri = Uri.parse(Platform.isIOS ? iosUrl : androidUrl);
    final fallback = Uri.parse(fallbackUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      _showSnackbar('Could not open map navigation.', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    showAppSnackbar(context, message, isError: isError);
  }

  void _showCoolerSheet(WaterCooler cooler) {
    final staleness = _stalenessInfo(cooler.lastVerifiedAt);

    final verifiedDate = DateTime.tryParse(cooler.lastVerifiedAt);
    final now = DateTime.now().toUtc();
    final diff = verifiedDate != null ? now.difference(verifiedDate) : const Duration(hours: 1);
    final canConfirm = diff.inMinutes >= 60;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(cooler.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900, color: AppColors.slate800, letterSpacing: -0.5)),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () => _launchDirections(cooler),
                  icon: const Icon(Icons.directions_rounded),
                  tooltip: 'Navigate',
                  style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _InfoRow(
              icon: statusIcon(cooler.status),
              iconColor: statusColor(cooler.status),
              label: 'Operational Status',
              value: cooler.status,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.verified_user_outlined,
              iconColor: staleness.color,
              label: 'Verified Freshness',
              value: staleness.text,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: _cupsIcon(cooler.hasCups),
              iconColor: _cupsColor(cooler.hasCups),
              label: 'Cup Supplies',
              value: _cupsLabel(cooler.hasCups, cooler.cupsType),
            ),
            const SizedBox(height: 24),
            if (cooler.status == 'Working') ...[
              SizedBox(
                width: double.infinity,
                child: canConfirm
                    ? FilledButton.icon(
                        onPressed: () => _confirmWorking(cooler),
                        icon: const Icon(Icons.verified_rounded, size: 18),
                        label: const Text('Report: Still Working'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.timer_outlined, size: 18),
                        label: Text('Verified (${60 - diff.inMinutes}m left for point reward)'),
                        style: FilledButton.styleFrom(
                          disabledBackgroundColor: AppColors.slate100,
                          disabledForegroundColor: AppColors.slate400,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
              ),
              const SizedBox(height: 14),
            ],
            const Text('Change reported status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate600)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatusButton(
                    label: 'Working',
                    color: AppColors.success,
                    icon: Icons.water_drop,
                    isActive: cooler.status == 'Working',
                    onTap: () => _updateCoolerStatus(cooler, 'Working'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusButton(
                    label: 'Empty',
                    color: AppColors.slate500,
                    icon: Icons.water_drop_outlined,
                    isActive: cooler.status == 'Empty',
                    onTap: () => _updateCoolerStatus(cooler, 'Empty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatusButton(
                    label: 'Broken',
                    color: AppColors.danger,
                    icon: Icons.report,
                    isActive: cooler.status == 'Broken',
                    onTap: () => _updateCoolerStatus(cooler, 'Broken'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _uploadPhoto(cooler),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Add Status Evidence Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (cooler.sponsor != null) ...[
              const SizedBox(height: 18),
              _SponsorBadge(sponsor: cooler.sponsor!),
            ],
          ],
        ),
      ),
    );
  }

  Marker _buildUserMarker(LatLng loc) => Marker(
        point: loc,
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.18),
                  shape: BoxShape.circle),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1)
                ],
              ),
            ),
          ],
        ),
      );

  List<WaterCooler> get _activeMarkers =>
      _searchMode && _searchController.text.isNotEmpty
          ? _searchResults
          : _coolers;

  @override
  Widget build(BuildContext context) {
    final initialCenter = _userLocation ?? _fallback;
    return Scaffold(
      appBar: AppBar(
        title: _searchMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                    hintText: 'Search Landmark/Point…', border: InputBorder.none),
                onSubmitted: _runSearch,
                textInputAction: TextInputAction.search,
              )
            : GestureDetector(
                onTap: _handleTitleTap,
                child: const Text('Sabil s.a.',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5)),
              ),
        centerTitle: !_searchMode,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_searchMode) ...[
            if (_searching)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
              )
            else
              IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () => _runSearch(_searchController.text)),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _searchDebounce?.cancel();
                setState(() {
                  _searchMode = false;
                  _searchResults = [];
                  _searchController.clear();
                  _showSearchList = false;
                });
              },
            ),
          ] else ...[
            IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => setState(() => _searchMode = true)),
            IconButton(
              icon: Icon(
                ApiService.isLoggedIn
                    ? Icons.account_circle_rounded
                    : Icons.account_circle_outlined,
                color: ApiService.isLoggedIn ? AppColors.teal400 : null,
              ),
              tooltip: ApiService.isLoggedIn ? 'Profile Panel' : 'User Verification',
              onPressed: () async {
                if (ApiService.isLoggedIn) {
                  await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  setState(() {});
                } else {
                  await _showAuthDialog();
                }
              },
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
              )
            else
              IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _fetchCoolers),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recenterOnUser,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Recenter GPS',
        child: const Icon(Icons.my_location_rounded),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14.5,
              onLongPress: (_, point) => _onMapLongPress(point),
              onTap: (_, __) {
                if (_searchMode) FocusScope.of(context).unfocus();
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sabil.app',
              ),
              if (_userLocation != null)
                MarkerLayer(markers: [_buildUserMarker(_userLocation!)]),
              PopupScope(
                child: MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 60,
                    size: const Size(44, 44),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(50),
                    popupOptions: PopupOptions(
                      popupController: _popupController,
                      popupBuilder: (_, marker) => const SizedBox.shrink(),
                    ),
                    markers: _activeMarkers.map((cooler) {
                      final color = statusColor(cooler.status);
                      final stalenessDays = DateTime.now()
                          .difference(
                              DateTime.tryParse(cooler.lastVerifiedAt) ??
                                  DateTime.now())
                          .inDays;
                      return Marker(
                        point: LatLng(cooler.latitude, cooler.longitude),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showCoolerSheet(cooler),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Icon(statusIcon(cooler.status),
                                    color: Colors.white, size: 20),
                              ),
                              if (stalenessDays > 14)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: stalenessDays > 30
                                          ? AppColors.danger
                                          : AppColors.warning,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    builder: (context, markers) {
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${markers.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_searchMode && _searching)
            const Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Material(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                      SizedBox(width: 12),
                      Text('Searching database records…'),
                    ],
                  ),
                ),
              ),
            ),
          if (_searchMode &&
              !_searching &&
              _searchController.text.isNotEmpty &&
              _searchResults.isEmpty)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Material(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                color: Colors.white,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.search_off_rounded, color: Colors.grey.shade400),
                      const SizedBox(width: 12),
                      Text(
                          'No registered sabil for "${_searchController.text}"',
                          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          if (_showSearchList && _searchResults.isNotEmpty)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              bottom: 120,
              child: Material(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                color: Colors.white,
                elevation: 6,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            '${_searchResults.length} index matches',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate600),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _showSearchList = false),
                            child: Icon(Icons.expand_less_rounded,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.slate100),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, indent: 16, endIndent: 16, color: AppColors.slate100),
                        itemBuilder: (_, i) {
                          final cooler = _searchResults[i];
                          final color = statusColor(cooler.status);
                          return ListTile(
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(statusIcon(cooler.status),
                                  color: color, size: 18),
                            ),
                            title: Text(cooler.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold, color: AppColors.slate800),
                                overflow: TextOverflow.ellipsis),
                            subtitle: Text('Status: ${cooler.status}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                            trailing: Icon(Icons.chevron_right_rounded,
                                color: Colors.grey.shade300),
                            onTap: () {
                              _mapController.move(
                                LatLng(cooler.latitude, cooler.longitude),
                                16.0,
                              );
                              setState(() => _showSearchList = false);
                              _showCoolerSheet(cooler);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_searchMode) ...[
            const Positioned(top: 12, right: 12, child: _Legend()),
            const Positioned(
              bottom: 88,
              left: 0,
              right: 0,
              child: Center(child: _HintBanner()),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthDialog extends StatefulWidget {
  const _AuthDialog();
  @override
  State<_AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<_AuthDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regUserCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _loginKey = GlobalKey<FormState>();
  final _regKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regUserCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isLogin = _tabs.index == 0;
    final key = isLogin ? _loginKey : _regKey;
    if (!key.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (isLogin) {
        await _api.userLogin(
            username: _loginUserCtrl.text.trim(),
            password: _loginPassCtrl.text);
      } else {
        await _api.register(
            username: _regUserCtrl.text.trim(),
            password: _regPassCtrl.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Access Sabil Network',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabs,
              tabs: const [Tab(text: 'Login'), Tab(text: 'Register')],
              labelColor: AppColors.primary,
              indicatorColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: TabBarView(
                controller: _tabs,
                children: [
                  Form(
                    key: _loginKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _loginUserCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                          enabled: !_loading,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _loginPassCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                          obscureText: true,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          enabled: !_loading,
                        ),
                      ],
                    ),
                  ),
                  Form(
                    key: _regKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _regUserCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (v.trim().length < 3) return 'Min 3 chars';
                            if (!RegExp(r"^[a-zA-Z0-9_]+$")
                                .hasMatch(v.trim())) {
                              return 'Alpha-numerics only';
                            }
                            return null;
                          },
                          enabled: !_loading,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _regPassCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Password (8+ chars)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.length < 8) return 'Min 8 characters';
                            return null;
                          },
                          enabled: !_loading,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style:
                      TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(_tabs.index == 0 ? 'Login' : 'Register'),
        ),
      ],
    );
  }
}

IconData _cupsIcon(bool? hasCups) {
  if (hasCups == null) return Icons.help_outline_rounded;
  return hasCups ? Icons.coffee_rounded : Icons.coffee_outlined;
}

Color _cupsColor(bool? hasCups) {
  if (hasCups == null) return AppColors.slate500;
  return hasCups ? AppColors.success : AppColors.danger;
}

String _cupsLabel(bool? hasCups, String? cupsType) {
  if (hasCups == null) return 'Unreported cups stock';
  if (!hasCups) return 'Out of cup supplies';
  if (cupsType == 'Communal') return 'Dispensing Reusable Cups';
  if (cupsType == 'Disposable') return 'Dispensing Disposable Stock';
  return 'Cups available';
}

_StalenessInfo _stalenessInfo(String lastVerifiedAt) {
  final verified = DateTime.tryParse(lastVerifiedAt);
  if (verified == null) return const _StalenessInfo('Unknown status freshness', Colors.grey);
  final days = DateTime.now().difference(verified).inDays;
  if (days <= 3) {
    return _StalenessInfo(
        days == 0 ? 'Verified today' : 'Verified $days day${days == 1 ? '' : 's'} ago',
        AppColors.success);
  }
  if (days <= 14) return _StalenessInfo('Stale: $days days ago', AppColors.warning);
  if (days <= 30) return _StalenessInfo('Stale: $days days ago', AppColors.danger);
  final weeks = (days / 7).floor();
  return _StalenessInfo(
      '$weeks weeks ago — requires fresh verification', AppColors.danger);
}

class _StalenessInfo {
  final String text;
  final Color color;
  const _StalenessInfo(this.text, this.color);
}

class _HintBanner extends StatelessWidget {
  const _HintBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.touch_app_rounded, color: Colors.white, size: 15),
          SizedBox(width: 6),
          Text('Long-press map location to propose cooler',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text('$label: ',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate600)),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate800),
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(color: AppColors.success, label: 'Working'),
          SizedBox(height: 6),
          _LegendItem(color: AppColors.slate500, label: 'Empty'),
          SizedBox(height: 6),
          _LegendItem(color: AppColors.danger, label: 'Broken'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate600)),
      ],
    );
  }
}

class _CupsToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CupsToggleChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _PhotoCategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? AppColors.primary : Colors.grey.shade500),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? AppColors.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusButton(
      {required this.label,
      required this.color,
      required this.icon,
      required this.isActive,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isActive ? color : color.withValues(alpha: 0.4),
              width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.white : color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isActive ? Colors.white : color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _SponsorBadge extends StatelessWidget {
  final Sponsor sponsor;

  const _SponsorBadge({required this.sponsor});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SponsorScreen(sponsor: sponsor)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.volunteer_activism_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Maintained by ${sponsor.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (sponsor.verified)
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 11, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Verified Sponsor Sadaka',
                          style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
