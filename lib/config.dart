class AppConfig {
  // Comment/uncomment these lines depending on where you are running your app

  // 🏠 LOCAL DEVELOPMENT (XAMPP)
  // Apache only serves ports 80/443 on this machine (confirmed via
  // netstat) -- there is no server on 8080, and the project lives at
  // htdocs/memberaccount, so the path prefix is required too.
  static const String baseUrl = "http://localhost/memberaccount";

  // ☁️ LIVE PRODUCTION HOSTING
  // static const String baseUrl = "https://member-account-backend.onrender.com";
}