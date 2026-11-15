import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/sabil_request.dart';

class SabilRequestRepository {
  SabilRequestRepository(this._api);

  final ApiClient _api;

  Future<SabilRequest> send(SabilRequestDraft draft) async =>
      SabilRequest.fromJson(await _api.post('/sabil-requests', draft.toJson()) as Map<String, dynamic>);

  Future<List<SabilRequest>> mine() async {
    final list = await _api.get('/sabil-requests/mine') as List;
    return [for (final r in list) SabilRequest.fromJson(r as Map<String, dynamic>)];
  }
}

final sabilRequestRepositoryProvider = Provider<SabilRequestRepository>(
  (ref) => SabilRequestRepository(ref.watch(apiClientProvider)),
);

final myRequestsProvider = FutureProvider.autoDispose<List<SabilRequest>>(
  (ref) => ref.watch(sabilRequestRepositoryProvider).mine(),
);
