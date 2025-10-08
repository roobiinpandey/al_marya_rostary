# Flutter Firebase Authentication App

This project is a Flutter application that integrates Firebase Authentication for user login, including support for Google sign-in.

## Project Structure

```
flutter_firebase_auth_app
├── lib
│   ├── main.dart                     # Entry point of the application
│   ├── core
│   │   ├── constants
│   │   │   └── app_constants.dart    # Constant values used throughout the app
│   │   ├── services
│   │   │   ├── firebase_auth_service.dart  # Handles Firebase authentication operations
│   │   │   └── google_sign_in_service.dart # Manages Google sign-in functionality
│   │   └── utils
│   │       └── validators.dart        # Utility functions for input validation
│   ├── data
│   │   ├── models
│   │   │   └── user_model.dart        # Represents the user data structure
│   │   └── repositories
│   │       └── auth_repository.dart   # Implements authentication repository
│   ├── domain
│   │   ├── entities
│   │   │   └── user_entity.dart       # Defines the user entity structure
│   │   └── repositories
│   │       └── auth_repository_interface.dart # Defines authentication methods
│   ├── presentation
│   │   ├── pages
│   │   │   ├── auth
│   │   │   │   ├── login_page.dart    # UI for user login
│   │   │   │   └── register_page.dart # UI for user registration
│   │   │   └── home
│   │   │       └── home_page.dart     # Main page after authentication
│   │   ├── widgets
│   │   │   ├── custom_button.dart      # Reusable button component
│   │   │   ├── custom_text_field.dart  # Reusable text field component
│   │   │   └── google_sign_in_button.dart # Button for Google sign-in
│   │   └── providers
│   │       └── auth_provider.dart      # Manages authentication state
│   └── config
│       └── firebase_config.dart        # Firebase configuration settings
├── android
│   └── app
│       └── google-services.json        # Firebase configuration for Android
├── ios
│   └── Runner
│       └── GoogleService-Info.plist    # Firebase configuration for iOS
├── web
│   └── index.html                     # Main HTML file for web version
├── pubspec.yaml                       # Flutter configuration file
└── README.md                          # Project documentation
```

## Setup Instructions

1. **Clone the repository:**
   ```
   git clone <repository-url>
   cd flutter_firebase_auth_app
   ```

2. **Install dependencies:**
   ```
   flutter pub get
   ```

3. **Configure Firebase:**
   - For Android, place the `google-services.json` file in the `android/app` directory.
   - For iOS, place the `GoogleService-Info.plist` file in the `ios/Runner` directory.
   - For web, ensure the Firebase configuration is set in `web/index.html`.

4. **Run the application:**
   ```
   flutter run
   ```

## Usage Guidelines

- The application provides a login page where users can authenticate using their email and password or via Google sign-in.
- After successful authentication, users are redirected to the home page.
- The application also supports user registration and password reset functionalities.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.