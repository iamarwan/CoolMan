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
import '../widgets/auth_dialog.dart';
import 'admin_screen.dart';
import 'map/add_cooler_dialog.dart';
import 'map/cooler_sheet.dart';
import 'map/map_markers.dart';
import 'map/map_widgets.dart';
import 'map/search_overlays.dart';
import 'profile_screen.dart';
import '../core/theme.dart';

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
      builder: (ctx) => const AuthDialog(),
    );
    if (result == true) setState(() {});
    return result == true;
  }

  Future<void> _onMapLongPress(LatLng point) async {
    final ok = await _ensureLoggedIn();
    if (!ok || !mounted) return;
    final request = await showAddCoolerDialog(context);
    if (request != null) _createCoolerWithPhotos(request, point);
  }

  Future<void> _createCoolerWithPhotos(
      NewCoolerRequest request, LatLng point) async {
    try {
      final created = await _api.createCoolerAndReturnId(
        name: request.name,
        latitude: point.latitude,
        longitude: point.longitude,
        hasCups: request.hasCups,
        cupsType: request.cupsType,
      );

      var failedPhotos = 0;
      for (final p in request.photos) {
        try {
          await _api.uploadPhoto(
            coolerId: created,
            imageFile: File(p.file.path),
            photoCategory: p.category,
          );
        } catch (e) {
          debugPrint('Photo upload failed: $e');
          failedPhotos++;
        }
      }
      if (failedPhotos == 0) {
        _showSnackbar('Cooler submitted successfully! +50 Trust pending.');
      } else {
        _showSnackbar(
          'Cooler submitted, but $failedPhotos of ${request.photos.length} '
          'photo(s) could not be uploaded. Open the cooler to add them again.',
          isError: true,
        );
      }
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

  /// Opens walking directions to the cooler in the person's maps app.
  /// Order: Google Maps app, then Google Maps in the browser, then OpenStreetMap.
  Future<void> _launchDirections(WaterCooler cooler) async {
    final lat = cooler.latitude;
    final lng = cooler.longitude;
    final candidates = <Uri>[
      if (Platform.isIOS)
        Uri.parse('maps://?daddr=$lat,$lng&dirflg=w')
      else
        Uri.parse('google.navigation:q=$lat,$lng&mode=w'),
      Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=walking'),
      Uri.parse('https://www.openstreetmap.org/directions?from=&to=$lat,$lng'),
    ];
    for (final uri in candidates) {
      try {
        // Try to open it directly; a false result or an error means "try the next one".
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (e) {
        debugPrint('Directions via $uri failed: $e');
      }
    }
    _showSnackbar('Could not open map navigation.', isError: true);
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    showAppSnackbar(context, message, isError: isError);
  }

  void _showCoolerSheet(WaterCooler cooler) {
    showCoolerSheet(
      context,
      cooler,
      loadPhotos: () => _api.fetchCoolerPhotos(cooler.id),
      onNavigate: () => _launchDirections(cooler),
      onConfirmWorking: () => _confirmWorking(cooler),
      onChangeStatus: (status) => _updateCoolerStatus(cooler, status),
      onAddPhoto: () => _uploadPhoto(cooler),
    );
  }

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
                MarkerLayer(markers: [buildUserMarker(_userLocation!)]),
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
                    markers: _activeMarkers
                        .map((cooler) => buildCoolerMarker(
                            cooler, () => _showCoolerSheet(cooler)))
                        .toList(),
                    builder: (context, markers) =>
                        buildClusterBubble(markers.length),
                  ),
                ),
              ),
            ],
          ),
          if (_searchMode && _searching) buildSearchingBanner(),
          if (_searchMode &&
              !_searching &&
              _searchController.text.isNotEmpty &&
              _searchResults.isEmpty)
            buildNoResultsBanner(_searchController.text),
          if (_showSearchList && _searchResults.isNotEmpty)
            buildSearchResultsList(
              results: _searchResults,
              onCollapse: () => setState(() => _showSearchList = false),
              onSelect: (cooler) {
                _mapController.move(
                  LatLng(cooler.latitude, cooler.longitude),
                  16.0,
                );
                setState(() => _showSearchList = false);
                _showCoolerSheet(cooler);
              },
            ),
          if (!_searchMode) ...[
            const Positioned(top: 12, right: 12, child: Legend()),
            const Positioned(
              bottom: 88,
              left: 0,
              right: 0,
              child: Center(child: HintBanner()),
            ),
          ],
        ],
      ),
    );
  }
}