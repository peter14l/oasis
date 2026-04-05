import 'package:oasis/services/session_registry_service.dart';

class AuthState {
  final RegisteredAccount? currentAccount;
  final List<RegisteredAccount> registeredAccounts;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.currentAccount,
    this.registeredAccounts = const [],
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    RegisteredAccount? currentAccount,
    List<RegisteredAccount>? registeredAccounts,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      currentAccount: currentAccount ?? this.currentAccount,
      registeredAccounts: registeredAccounts ?? this.registeredAccounts,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}
