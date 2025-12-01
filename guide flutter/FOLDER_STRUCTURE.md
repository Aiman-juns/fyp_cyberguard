# CyberGuard - Project Folder Structure

```
lib/
├── main.dart                          # App entry point
│
├── config/
│   ├── supabase_config.dart          # Supabase initialization
│   ├── theme.dart                     # Material 3 theme (light/dark)
│   └── router_config.dart             # GoRouter configuration
│
├── auth/
│   ├── models/
│   │   └── user_model.dart            # User data model
│   ├── providers/
│   │   ├── auth_provider.dart         # Auth state management (Riverpod)
│   │   └── user_provider.dart         # Current user provider
│   └── screens/
│       ├── login_screen.dart          # Email/Password login
│       └── register_screen.dart       # Registration with avatar generation
│
├── core/
│   ├── models/
│   │   ├── resource_model.dart        # Resource data model
│   │   ├── question_model.dart        # Question data model
│   │   ├── news_model.dart            # News article model
│   │   └── user_progress_model.dart   # Progress tracking model
│   ├── providers/
│   │   ├── resource_provider.dart     # Resource fetching (Riverpod)
│   │   ├── question_provider.dart     # Question fetching
│   │   ├── news_provider.dart         # News feed provider
│   │   ├── user_progress_provider.dart # Progress tracking
│   │   └── avatar_service.dart        # DiceBear avatar generation
│   ├── services/
│   │   ├── supabase_service.dart      # Supabase CRUD operations
│   │   ├── storage_service.dart       # File upload to Supabase Storage
│   │   └── url_checker_service.dart   # Mock URL safety checker API
│   └── utils/
│       ├── constants.dart             # App constants
│       ├── validators.dart            # Input validation logic
│       └── extensions.dart            # Dart extensions
│
├── features/
│   ├── shell/
│   │   ├── screens/
│   │   │   └── app_shell.dart         # Main shell with bottom nav
│   │   ├── widgets/
│   │   │   ├── custom_drawer.dart     # Navigation drawer
│   │   │   ├── bottom_nav_bar.dart    # Bottom navigation bar
│   │   │   └── user_profile_header.dart # Drawer header
│   │   └── providers/
│   │       └── shell_provider.dart    # Shell state (active tab)
│   │
│   ├── resources/
│   │   ├── screens/
│   │   │   ├── resources_list_screen.dart   # Main resources tab
│   │   │   └── resource_detail_screen.dart  # Resource detail with back button
│   │   ├── widgets/
│   │   │   └── resource_card.dart           # Resource list item
│   │   └── providers/
│   │       └── resources_providers.dart     # Resources state management
│   │
│   ├── training/
│   │   ├── screens/
│   │   │   ├── training_hub_screen.dart           # Main training screen (3 cards)
│   │   │   ├── phishing_module_screen.dart        # Phishing swipe interface
│   │   │   ├── password_dojo_screen.dart          # Password strength input
│   │   │   ├── cyber_attack_analyst_screen.dart   # Attack scenario MCQ
│   │   │   └── feedback_dialog.dart               # Feedback modal
│   │   ├── widgets/
│   │   │   ├── module_card.dart                   # Training module card
│   │   │   ├── phishing_card_swiper.dart          # Swipe detection UI
│   │   │   ├── password_strength_meter.dart       # Strength indicator
│   │   │   ├── scenario_question_widget.dart      # MCQ display
│   │   │   └── bottom_sheet_feedback.dart         # Feedback sheet
│   │   └── providers/
│   │       ├── training_providers.dart            # Training state
│   │       ├── phishing_provider.dart             # Phishing module logic
│   │       ├── password_provider.dart             # Password module logic
│   │       └── attack_provider.dart               # Attack module logic
│   │
│   ├── digital_assistant/
│   │   ├── screens/
│   │   │   └── url_checker_screen.dart            # URL safety checker
│   │   ├── widgets/
│   │   │   ├── url_input_field.dart               # Input widget
│   │   │   └── safety_result_widget.dart          # Result display
│   │   └── providers/
│   │       └── url_checker_provider.dart          # URL checking logic
│   │
│   ├── performance/
│   │   ├── screens/
│   │   │   └── performance_screen.dart            # Stats & medals tab
│   │   ├── widgets/
│   │   │   ├── medal_showcase.dart                # Horizontal medal list
│   │   │   ├── module_progress_card.dart          # Progress circular indicator
│   │   │   └── level_badge.dart                   # Level display
│   │   └── providers/
│   │       └── performance_provider.dart          # Performance calculations
│   │
│   ├── news/
│   │   ├── screens/
│   │   │   ├── news_feed_screen.dart              # News list tab
│   │   │   ├── news_detail_screen.dart            # Full article with back button
│   │   │   └── scam_stats_placeholder.dart        # Chart placeholder
│   │   ├── widgets/
│   │   │   └── news_card.dart                     # News feed item
│   │   └── providers/
│   │       └── news_provider.dart                 # News fetching
│   │
│   └── admin/
│       ├── screens/
│       │   ├── admin_dashboard_screen.dart        # Main admin screen
│       │   ├── question_management_screen.dart    # Question list with TabBar
│       │   ├── add_question_screen.dart           # Add/Edit question form
│       │   └── media_upload_screen.dart           # Media picker & upload
│       ├── widgets/
│       │   ├── question_list_tile.dart            # Question item with swipe
│       │   ├── module_tab_bar.dart                # Module selector
│       │   └── question_form_widget.dart          # Form widget
│       └── providers/
│           ├── admin_providers.dart               # Admin state
│           └── question_management_provider.dart  # Question CRUD
│
└── shared/
    ├── widgets/
    │   ├── custom_app_bar.dart         # Standard app bar with back button
    │   ├── loading_widget.dart         # Loading indicator
    │   ├── error_widget.dart           # Error display
    │   └── custom_button.dart          # Reusable button styles
    ├── helpers/
    │   ├── snackbar_helper.dart        # Snackbar notifications
    │   └── dialog_helper.dart          # Dialog utilities
    └── theme/
        └── app_colors.dart             # Color constants
```

## Additional Files

```
pubspec.yaml                    # Dependencies configuration
analysis_options.yaml           # Lint rules
README.md                       # Project documentation
.env.example                    # Environment variables template
.gitignore                      # Git ignore rules
```

## Notes on Structure

1. **Modular Design:** Each feature is self-contained with its own screens, widgets, and providers.
2. **Core Layer:** Shared models, services, and providers used across features.
3. **Config Layer:** Centralized app configuration (Supabase, Router, Theme).
4. **Shared Layer:** Common widgets and utilities accessible from anywhere.
5. **Riverpod Code Generation:** Models use `@immutable` and `part 'file.g.dart'` for code generation.
6. **GoRouter:** Router configuration in `config/router_config.dart` with ShellRoute for persistent navigation.

## Generated Files (Riverpod & Build Runner)

The following files will be **auto-generated** by `flutter pub run build_runner build`:

```
lib/config/router_config.g.dart
lib/auth/providers/*.g.dart
lib/core/providers/*.g.dart
lib/features/**/*_provider.g.dart
```

These should be in `.gitignore` to avoid version control conflicts.
