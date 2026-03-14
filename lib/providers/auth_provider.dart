import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = true;
  String? _error;

  static final _googleSignIn = GoogleSignIn(
    // Add your Web Client ID from Google Cloud Console
    // (used by Supabase to verify the token)
    serverClientId: '692761730622-0covaq42pvj49p7ge431hka73f30fks8.apps.googleusercontent.com',
  );

  User? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  AuthProvider() {
    _user = Supabase.instance.client.auth.currentUser;
    _loading = false;
    notifyListeners();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      _error = null;
      notifyListeners();
    });
  }

  // ─── Google Sign-In (native — works on Android & iOS) ───────
  Future<String?> signInWithGoogle() async {
    _error = null;
    notifyListeners();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Sign-in cancelled';

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) return 'Could not get Google ID token';

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return null;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return _error;
    } catch (e) {
      _error = 'Google sign-in failed: ${e.toString()}';
      notifyListeners();
      return _error;
    }
  }

  // ─── Email Sign-In ───────────────────────────────────────────
  Future<String?> signInWithEmail(String email, String password) async {
    _error = null;
    notifyListeners();
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (res.user == null) {
        _error = 'Sign in failed. Check your credentials.';
        notifyListeners();
        return _error;
      }
      return null;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return _error;
    } catch (e) {
      _error = 'Unexpected error. Try again.';
      notifyListeners();
      return _error;
    }
  }

  // ─── Email Sign-Up ───────────────────────────────────────────
  Future<String?> signUp(String email, String password, String name) async {
    _error = null;
    notifyListeners();
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );
      if (res.user == null) {
        _error = 'Sign up failed. Try again.';
        notifyListeners();
        return _error;
      }
      return null;
    } on AuthException catch (e) {
      _error = e.message;
      notifyListeners();
      return _error;
    } catch (e) {
      _error = 'Unexpected error. Try again.';
      notifyListeners();
      return _error;
    }
  }

  // ─── Apple Sign-In (coming soon) ─────────────────────────────
  Future<String?> signInWithApple() async {
    _error = 'Apple Sign-In coming soon. Please use Google or Email.';
    notifyListeners();
    return _error;
  }

  // ─── Sign Out ────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    _user = null;
    notifyListeners();
  }
}
