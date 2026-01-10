import 'package:flutter/foundation.dart';

/// Base ViewModel class for MVVM pattern
/// Provides common functionality for all ViewModels
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Set loading state
  @protected
  void setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  @protected
  void setError(String? error) {
    if (_isDisposed) return;
    _error = error;
    notifyListeners();
  }

  /// Clear error state
  void clearError() {
    if (_isDisposed) return;
    _error = null;
    notifyListeners();
  }

  /// Safe notify listeners (checks if disposed)
  @protected
  void safeNotifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }

  /// Execute an async operation with loading and error handling
  @protected
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showLoading = true,
  }) async {
    try {
      if (showLoading) setLoading(true);
      clearError();

      final result = await operation();

      if (showLoading) setLoading(false);
      return result;
    } catch (e) {
      setError(errorMessage ?? e.toString());
      if (showLoading) setLoading(false);
      debugPrint('ViewModel error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
