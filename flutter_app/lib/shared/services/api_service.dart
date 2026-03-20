import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Dio HTTP client for communicating with the FastAPI backend.
/// All Flutter screens talk to the backend through this service.
/// The backend then handles AI (Gemini), ML models, and database operations.
class ApiService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add auth token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  // ── Check-In ──
  Future<Response> submitCheckIn({
    required int painLevel,
    required List<String> symptoms,
    required String mood,
  }) async {
    return _dio.post('/api/recovery/checkin', data: {
      'pain_level': painLevel,
      'symptoms': symptoms,
      'mood': mood,
    });
  }

  // ── AI Chat ──
  Future<Response> sendChatMessage({
    required String message,
    String language = 'en',
  }) async {
    return _dio.post('/api/chat', data: {
      'message': message,
      'language': language,
    });
  }

  // ── Diet ──
  Future<Response> getDietPlan({
    required String surgeryType,
    required int daysSinceSurgery,
    required List<String> allergies,
  }) async {
    return _dio.get('/api/recovery/diet', queryParameters: {
      'surgery_type': surgeryType,
      'day': daysSinceSurgery,
      'allergies': allergies.join(','),
    });
  }

  // ── Hospitals ──
  Future<Response> getHospitals({
    double? lat,
    double? lng,
    String? type,
  }) async {
    return _dio.get('/api/hospitals', queryParameters: {
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (type != null) 'type': type,
    });
  }

  // ── Profile ──
  Future<Response> saveProfile(Map<String, dynamic> profileData) async {
    return _dio.post('/api/patients/profile', data: profileData);
  }

  // ── Mental Health ──
  Future<Response> submitMoodCheckIn({
    required String mood,
    String? notes,
  }) async {
    return _dio.post('/api/recovery/mood', data: {
      'mood': mood,
      'notes': notes,
    });
  }
}
