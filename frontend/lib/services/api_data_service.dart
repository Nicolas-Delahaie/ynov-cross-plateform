import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../interfaces/i_data_service.dart';
import '../models/profile.dart';
import 'data_service.dart';

/// Charge les profils depuis le backend MACEN (FastAPI) via `GET /api/persons`.
///
/// Implémente l'interface synchrone [IDataService] : tous les profils sont
/// récupérés une seule fois dans [init], puis [getRandomProfiles] sert des
/// sous-ensembles mélangés — même contrat que le [DataService] local, ce qui
/// permet de brancher l'API sans toucher au repository ni au provider.
///
/// Si le backend est injoignable, bascule automatiquement sur [DataService]
/// (profils locaux dans `assets/data/profiles.json`) afin que le jeu reste
/// jouable sans backend lancé.
class ApiDataService implements IDataService {
  /// URL de base du backend.
  ///
  /// - Web / Chrome (même PC)   : `http://localhost:8000`
  /// - Émulateur Android         : `http://10.0.2.2:8000`
  /// - Téléphone réel (même WiFi): `http://<IP-du-PC>:8000`
  final String baseUrl;

  /// Nombre de profils récupérés au démarrage (pool dans lequel on pioche).
  final int fetchCount;

  final http.Client _client;
  final DataService _fallback = DataService();
  List<Profile> _allProfiles = [];
  bool _usingFallback = false;
  final Random _random = Random();

  ApiDataService({
    this.baseUrl = 'http://localhost:8000',
    this.fetchCount = 100,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// `true` si le backend était injoignable et qu'on sert les profils locaux.
  bool get isUsingFallback => _usingFallback;

  @override
  Future<void> init() async {
    await loadProfiles();
  }

  @override
  Future<void> loadProfiles() async {
    try {
      final uri = Uri.parse('$baseUrl/api/persons').replace(
        queryParameters: {'limit': fetchCount.toString()},
      );
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        await _loadFallback();
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final persons = (data['persons'] as List<dynamic>?) ?? [];

      _allProfiles = persons.map((p) {
        final m = p as Map<String, dynamic>;
        return Profile(
          id: m['id'].toString(),
          imageUrl: m['photo_url'] as String,
          // backend: "pro" | "interpol"  ->  front: linkedin | interpol
          type: m['type'] == 'pro'
              ? ProfileType.linkedin
              : ProfileType.interpol,
          context: m['post'] as String?, // métier (PRO) ou délit (Interpol)
        );
      }).toList();
      _usingFallback = false;
    } catch (_) {
      // Backend injoignable -> bascule sur les profils locaux.
      await _loadFallback();
    }
  }

  Future<void> _loadFallback() async {
    await _fallback.loadProfiles();
    _allProfiles = _fallback.getRandomProfiles(_fallback.availableProfilesCount);
    _usingFallback = true;
  }

  @override
  List<Profile> getRandomProfiles(int count) {
    if (_allProfiles.isEmpty) return [];
    final shuffled = List<Profile>.from(_allProfiles)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  @override
  int get availableProfilesCount => _allProfiles.length;
}
