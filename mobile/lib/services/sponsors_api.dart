// lib/services/sponsors_api.dart
//
// Server calls about sponsors: the public list/detail pages, and the admin
// actions (create, verify, delete, attach to a cooler).

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../models/water_cooler.dart';
import '../models/sponsor.dart';
import 'api_client.dart';
import 'session_store.dart';

mixin class SponsorsApi {
  // ─── Public ───

  Future<List<Sponsor>> fetchAllSponsors() async {
    final response =
        await http.get(apiUri('/sponsors')).timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Sponsor.fromJson(e)).toList();
    }
    throw Exception('Failed to fetch sponsors (${response.statusCode}).');
  }

  Future<Sponsor> fetchSponsor(String sponsorId) async {
    final response = await http
        .get(apiUri('/sponsors/$sponsorId'))
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      return Sponsor.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch sponsor (${response.statusCode}).');
  }

  // ─── Admin ───

  Future<Sponsor> createSponsor({
    required String name,
    required String sponsorType,
    String? contact,
  }) async {
    final response = await http
        .post(
          apiUri('/admin/sponsors'),
          headers: SessionStore.adminHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode({
            'name': name,
            'sponsor_type': sponsorType,
            if (contact != null && contact.isNotEmpty) 'contact': contact,
          }),
        )
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 201) {
      return Sponsor.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create sponsor (${response.statusCode}).');
  }

  Future<bool> verifySponsor(String sponsorId) async {
    final response = await http
        .patch(apiUri('/admin/sponsors/$sponsorId/verify'),
            headers: SessionStore.adminHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) return true;
    throw Exception('Failed to verify sponsor (${response.statusCode}).');
  }

  Future<bool> deleteSponsor(String sponsorId) async {
    final response = await http
        .delete(apiUri('/admin/sponsors/$sponsorId'),
            headers: SessionStore.adminHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200 || response.statusCode == 204) return true;
    throw Exception('Failed to delete sponsor (${response.statusCode}).');
  }

  Future<WaterCooler> assignSponsor({
    required String coolerId,
    required String sponsorId,
  }) async {
    final response = await http
        .patch(
          apiUri('/admin/coolers/$coolerId/assign-sponsor'),
          headers: SessionStore.adminHeaders({'Content-Type': 'application/json'}),
          body: jsonEncode({'sponsor_id': sponsorId}),
        )
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      return WaterCooler.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to assign sponsor (${response.statusCode}).');
  }

  Future<WaterCooler> removeSponsor(String coolerId) async {
    final response = await http
        .delete(apiUri('/admin/coolers/$coolerId/assign-sponsor'),
            headers: SessionStore.adminHeaders())
        .timeout(ApiConfig.timeout);
    if (response.statusCode == 200) {
      return WaterCooler.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to remove sponsor (${response.statusCode}).');
  }
}
