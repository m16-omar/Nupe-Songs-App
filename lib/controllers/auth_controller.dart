import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../services/storage_service.dart';

class AuthController extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isGuest = false;
  bool _isLoading = false;
  bool _isStaff = false;
  String? _userName;
  String? _userEmail;
  String? _token;
  String? _refreshToken;

  final StorageService _storage = StorageService();
  bool _isStorageInitialized = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;
  bool get isStaff => _isStaff;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get token => _token;
  String? get refreshToken => _refreshToken;

  int _activePort = 8000;

  String get baseUrl => ApiConstants.baseUrl;

  Future<void> _ensureStorage() async {
    if (!_isStorageInitialized) {
      await _storage.init();
      _isStorageInitialized = true;
    }
  }

  Future<http.Response> _sendRequest(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final mergedHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    if (ApiConstants.useLiveBackend) {
      final uri = Uri.parse('${ApiConstants.baseUrl}$path');
      final timeoutDuration = const Duration(seconds: 30);
      try {
        final http.Response response;
        if (method == 'POST') {
          response = await http.post(
            uri,
            headers: mergedHeaders,
            body: body,
          ).timeout(timeoutDuration);
        } else if (method == 'GET') {
          response = await http.get(
            uri,
            headers: mergedHeaders,
          ).timeout(timeoutDuration);
        } else {
          throw UnsupportedError('Unsupported HTTP method: $method');
        }
        return response;
      } catch (e) {
        if (kDebugMode) {
          print('Request error to live backend path $path: $e');
        }
        rethrow;
      }
    }

    final ports = [8000];
    
    // Prioritize currently active port
    ports.remove(_activePort);
    ports.insert(0, _activePort);

    dynamic lastException;

    for (final port in ports) {
      final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
      final uri = Uri.parse('http://$host:$port/api$path');

      try {
        final http.Response response;

        if (method == 'POST') {
          response = await http.post(
            uri,
            headers: mergedHeaders,
            body: body,
          ).timeout(const Duration(seconds: 4));
        } else if (method == 'GET') {
          response = await http.get(
            uri,
            headers: mergedHeaders,
          ).timeout(const Duration(seconds: 4));
        } else {
          throw UnsupportedError('Unsupported HTTP method: $method');
        }

        // Request succeeded, remember this port
        _activePort = port;
        return response;
      } on SocketException catch (e) {
        lastException = e;
        if (kDebugMode) {
          print('Connection refused on port $port for path $path. Trying next candidate...');
        }
      } catch (e) {
        lastException = e;
        if (kDebugMode) {
          print('Request error on port $port for path $path: $e. Trying next candidate...');
        }
      }
    }

    throw lastException ?? Exception('Connection failed to all host candidates');
  }

  Future<void> tryAutoLogin() async {
    if (kDebugMode) {
      print('tryAutoLogin started');
    }
    await _ensureStorage();
    
    final wasGuest = _storage.getBool('auth_is_guest', defaultValue: false);
    if (wasGuest) {
      if (kDebugMode) {
        print('tryAutoLogin: user was guest, returning');
      }
      _isGuest = true;
      _isAuthenticated = false;
      notifyListeners();
      return;
    }

    String? savedToken = _storage.getString('auth_token');
    final savedRefreshToken = _storage.getString('auth_refresh_token');
    if (kDebugMode) {
      print('tryAutoLogin: savedToken is $savedToken, savedRefreshToken is $savedRefreshToken');
    }
    
    if (savedToken == null && savedRefreshToken == null) {
      if (kDebugMode) {
        print('tryAutoLogin: no saved tokens, returning');
      }
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      if (savedToken != null) {
        final response = await _sendRequest(
          'GET',
          '/auth/me',
          headers: {'Authorization': 'Bearer $savedToken'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _token = savedToken;
          _refreshToken = savedRefreshToken;
          _isAuthenticated = true;
          _isGuest = false;
          _isStaff = data['is_staff'] as bool? ?? false;
          _userName = data['full_name'] as String? ?? 
              '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
          _userEmail = data['email'] as String?;
          
          await _storage.setString('auth_username', _userName ?? '');
          await _storage.setString('auth_email', _userEmail ?? '');
          await _storage.setBool('auth_is_authenticated', true);
          await _storage.setBool('auth_is_staff', _isStaff);
          if (kDebugMode) {
            print('tryAutoLogin: auto-login succeeded with saved token for $_userName');
          }
          return;
        } else {
          if (kDebugMode) {
            print('tryAutoLogin: profile retrieval failed (status ${response.statusCode}). Attempting token refresh...');
          }
        }
      }

      // Access token was null or expired/invalid. Try to refresh.
      if (savedRefreshToken != null) {
        final refreshSuccess = await _refreshAccessToken();
        if (refreshSuccess) {
          savedToken = _token;
          if (savedToken != null) {
            final response = await _sendRequest(
              'GET',
              '/auth/me',
              headers: {'Authorization': 'Bearer $savedToken'},
            );

            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              _isAuthenticated = true;
              _isGuest = false;
              _isStaff = data['is_staff'] as bool? ?? false;
              _userName = data['full_name'] as String? ?? 
                  '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
              _userEmail = data['email'] as String?;
              
              await _storage.setString('auth_username', _userName ?? '');
              await _storage.setString('auth_email', _userEmail ?? '');
              await _storage.setBool('auth_is_authenticated', true);
              await _storage.setBool('auth_is_staff', _isStaff);
              if (kDebugMode) {
                print('tryAutoLogin: auto-login succeeded after token refresh for $_userName');
              }
              return;
            }
          }
        }
      }

      if (kDebugMode) {
        print('tryAutoLogin: auto-login failed because tokens are invalid or expired');
      }
      await _clearSession();
    } catch (e) {
      if (kDebugMode) {
        print('Auto-login network request failed: $e');
      }
      
      final wasAuthed = _storage.getBool('auth_is_authenticated', defaultValue: false);
      if (wasAuthed) {
        _token = savedToken;
        _refreshToken = savedRefreshToken;
        _isAuthenticated = true;
        _isGuest = false;
        _isStaff = _storage.getBool('auth_is_staff', defaultValue: false);
        _userName = _storage.getString('auth_username') ?? 'User';
        _userEmail = _storage.getString('auth_email');
        if (kDebugMode) {
          print('tryAutoLogin: network failed but fell back to cached auth session for $_userName');
        }
      } else {
        await _clearSession();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _refreshAccessToken() async {
    final savedRefreshToken = _storage.getString('auth_refresh_token');
    if (savedRefreshToken == null) return false;

    try {
      final response = await _sendRequest(
        'POST',
        '/auth/token/refresh',
        body: json.encode({
          'refresh': savedRefreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['access'] as String;
        final newRefreshToken = data['refresh'] as String?;

        _token = accessToken;
        await _storage.setString('auth_token', accessToken);
        
        if (newRefreshToken != null) {
          _refreshToken = newRefreshToken;
          await _storage.setString('auth_refresh_token', newRefreshToken);
        }
        
        if (kDebugMode) {
          print('Token refreshed successfully');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during token refresh: $e');
      }
    }
    return false;
  }

  Future<(bool, String?)> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    notifyListeners();
    await _ensureStorage();

    String loginIdentifier = usernameOrEmail.trim();
    if (!loginIdentifier.contains('@')) {
      loginIdentifier = loginIdentifier.replaceAll(' ', '_').replaceAll(RegExp(r'[^a-zA-Z0-9@\.\+\-_]'), '').toLowerCase();
    }

    try {
      final response = await _sendRequest(
        'POST',
        '/auth/login',
        body: json.encode({
          'username': loginIdentifier,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final accessToken = data['access'] as String;
        final refreshToken = data['refresh'] as String;
        
        final meResponse = await _sendRequest(
          'GET',
          '/auth/me',
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (meResponse.statusCode == 200) {
          final meData = json.decode(meResponse.body);
          _token = accessToken;
          _refreshToken = refreshToken;
          _isAuthenticated = true;
          _isGuest = false;
          _isStaff = meData['is_staff'] as bool? ?? false;
          _userName = meData['full_name'] as String? ??
              '${meData['first_name'] ?? ''} ${meData['last_name'] ?? ''}'.trim();
          _userEmail = meData['email'] as String?;
          
          await _storage.setString('auth_token', accessToken);
          await _storage.setString('auth_refresh_token', refreshToken);
          await _storage.setString('auth_username', _userName ?? '');
          await _storage.setString('auth_email', _userEmail ?? '');
          await _storage.setBool('auth_is_authenticated', true);
          await _storage.setBool('auth_is_guest', false);
          await _storage.setBool('auth_is_staff', _isStaff);

          _isLoading = false;
          notifyListeners();
          return (true, null);
        } else {
          final errorMsg = _parseErrorBody(meResponse);
          _isLoading = false;
          notifyListeners();
          return (false, errorMsg);
        }
      } else {
        final errorMsg = _parseErrorBody(response);
        _isLoading = false;
        notifyListeners();
        return (false, errorMsg);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login execution error: $e');
      }
      _isLoading = false;
      notifyListeners();
      return (false, 'Network connection failed. Please make sure the server is reachable.');
    }
  }

  Future<(bool, String?)> signup(String firstName, String lastName, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    await _ensureStorage();

    try {
      final response = await _sendRequest(
        'POST',
        '/auth/register',
        body: json.encode({
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        _isLoading = false;
        // Automatically login using email after successful registration
        return await login(email.trim(), password);
      } else {
        final errorMsg = _parseErrorBody(response);
        _isLoading = false;
        notifyListeners();
        return (false, errorMsg);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Registration request failed: $e');
      }
      _isLoading = false;
      notifyListeners();
      return (false, 'Network connection failed. Please make sure the server is reachable.');
    }
  }

  void continueAsGuest() async {
    _isAuthenticated = false;
    _isGuest = true;
    _userName = null;
    _userEmail = null;
    _token = null;
    _refreshToken = null;
    await _ensureStorage();
    await _storage.setBool('auth_is_guest', true);
    await _storage.remove('auth_token');
    await _storage.remove('auth_refresh_token');
    await _storage.remove('auth_username');
    await _storage.remove('auth_email');
    await _storage.setBool('auth_is_authenticated', false);
    notifyListeners();
  }

  void logout() async {
    await _ensureStorage();
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _token = null;
    _refreshToken = null;
    _isAuthenticated = false;
    _isGuest = false;
    _isStaff = false;
    _userName = null;
    _userEmail = null;
    await _storage.remove('auth_token');
    await _storage.remove('auth_refresh_token');
    await _storage.remove('auth_username');
    await _storage.remove('auth_email');
    await _storage.remove('auth_is_guest');
    await _storage.remove('auth_is_authenticated');
    await _storage.remove('auth_is_staff');
  }

  Future<(bool, String?)> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    notifyListeners();

    // Simulated action because DRF API does not expose a reset password route
    await Future.delayed(const Duration(milliseconds: 1500));

    if (email.trim().isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
      _isLoading = false;
      notifyListeners();
      return (false, 'Please enter a valid email address.');
    }

    _isLoading = false;
    notifyListeners();
    return (true, null);
  }

  String _parseErrorBody(http.Response response) {
    try {
      final body = json.decode(response.body);
      if (body is Map) {
        if (body.containsKey('detail')) {
          return body['detail'].toString();
        }
        
        final errors = <String>[];
        body.forEach((key, value) {
          if (value is List) {
            errors.add('${_capitalize(key)}: ${value.join(", ")}');
          } else {
            errors.add('${_capitalize(key)}: $value');
          }
        });
        if (errors.isNotEmpty) {
          return errors.join('\n');
        }
      }
      return 'Error ${response.statusCode}: ${response.reasonPhrase}';
    } catch (_) {
      return 'Request failed with status ${response.statusCode}';
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
