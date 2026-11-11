import 'package:flutter_riverpod/misc.dart';
import 'package:sabil/core/api_client.dart';
import 'package:sabil/core/cache_store.dart';
import 'package:sabil/core/providers.dart';
import 'package:sabil/features/cooler/cooler_repository.dart';
import 'package:sabil/features/map/bbox.dart';
import 'package:sabil/models/cooler.dart';

CoolerPin pin(String id, double lat, double lng, [CoolerStatus s = CoolerStatus.working]) =>
    CoolerPin(id: id, lat: lat, lng: lng, status: s);

Cooler cooler({String id = 'c1', CoolerStatus status = CoolerStatus.working}) => Cooler(
      id: id,
      name: 'Maadi Metro Station',
      lat: 29.96,
      lng: 31.25,
      status: status,
      lastVerifiedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      createdAt: DateTime.now(),
      hasCups: true,
      cupsType: CupsType.disposable,
    );

class FakeCoolerRepository extends CoolerRepository {
  FakeCoolerRepository() : super(ApiClient(baseUrl: 'http://fake'));

  /// Each call to [pins] completes with the next queued result.
  final List<Future<({List<CoolerPin> pins, bool truncated})> Function()> pinResponses = [];
  final List<Bbox> pinRequests = [];
  Cooler detailResult = cooler();
  int confirmCalls = 0;

  @override
  Future<({List<CoolerPin> pins, bool truncated})> pins(Bbox area, {int limit = 600}) {
    pinRequests.add(area);
    return pinResponses.removeAt(0)();
  }

  @override
  Future<Cooler> detail(String id) async => detailResult;

  @override
  Future<({int trustScore, int pointsAwarded, DateTime verifiedAt})> confirm(String id) async {
    confirmCalls++;
    return (trustScore: 5, pointsAwarded: 5, verifiedAt: DateTime.now());
  }
}

List<Override> baseOverrides(FakeCoolerRepository repo, {CacheStore? cache}) => [
      cacheStoreProvider.overrideWithValue(cache ?? CacheStore(null)),
      coolerRepositoryProvider.overrideWithValue(repo),
    ];
