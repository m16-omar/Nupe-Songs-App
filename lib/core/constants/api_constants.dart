import 'dart:io';

class ApiConstants {
  // Live Render Backend URL
  static const String liveBaseUrl = 'https://nupe-songs-backend1.onrender.com/api';
  
  // Local Backend fallback URL
  static String get localBaseUrl => 'http://${Platform.isAndroid ? '10.0.2.2' : '127.0.0.1'}:8000/api';
  
  // Toggle to use live backend or local backend
  static const bool useLiveBackend = true;
  
  // Get active baseUrl
  static String get baseUrl => useLiveBackend ? liveBaseUrl : localBaseUrl;
}
