class ApiConfig {
  // Base URL - change for production
  static const String baseUrl = 'http://localhost:4000/api';
  
  // Auth endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authOAuth = '/auth/oauth';
  static const String authRefresh = '/auth/refresh';
  static const String authMe = '/auth/me';
  static const String authOnboarding = '/auth/onboarding';
  static const String authLogout = '/auth/logout';
  
  // Design endpoints
  static const String designs = '/designs';
  static const String designStats = '/designs/stats';
  
  // Style endpoints
  static const String styles = '/styles';
  static const String roomTypes = '/styles/room-types';
  
  // Token endpoints
  static const String tokenPackages = '/tokens/packages';
  static const String tokenBalance = '/tokens/balance';
  static const String tokenTransactions = '/tokens/transactions';
  static const String tokenPurchase = '/tokens/purchase';
  static const String tokenPromo = '/tokens/promo';
}
