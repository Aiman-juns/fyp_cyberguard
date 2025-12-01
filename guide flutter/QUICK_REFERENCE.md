# CyberGuard - Quick Reference Guide

## 📚 Documentation Files

| File | Purpose | Read When |
|------|---------|-----------|
| `PRD.md` | Full product specification | Understanding overall vision |
| `FOLDER_STRUCTURE.md` | Architecture explanation | Navigating codebase |
| `SUPABASE_SCHEMA.sql` | Database setup script | Setting up backend |
| `PHASE_1_COMPLETION.md` | Phase 1 details | Understanding auth system |
| `PHASE_1_STATE.md` | Current project status | Checking what's done |
| `README.md` | Project overview | Getting started |

---

## 🚀 Getting Started (First Time)

```bash
# 1. Get to project directory
cd "c:\flutter project\cats_project\cats_flutter"

# 2. Get all dependencies
flutter pub get

# 3. Configure Supabase credentials
# Edit: lib/config/supabase_config.dart
# Update: supabaseUrl and supabaseAnonKey

# 4. Run the app
flutter run
```

---

## 🔑 Key Files to Know

### Authentication
- `lib/auth/providers/auth_provider.dart` - Main auth logic
- `lib/auth/screens/login_screen.dart` - Login UI
- `lib/auth/screens/register_screen.dart` - Register UI

### Theme & UI
- `lib/shared/theme/app_colors.dart` - All colors
- `lib/shared/theme/app_theme.dart` - Light/dark themes
- `lib/config/router_config.dart` - Navigation routes

### Backend
- `lib/config/supabase_config.dart` - Supabase setup
- `lib/core/providers/avatar_service.dart` - Avatar generation

### Entry Point
- `lib/main.dart` - App initialization

---

## 🎨 The CyberGuard Color Palette

```
Primary Blue:    #0066CC    (Cybersecurity)
Success Green:   #00CC66    (Secure)
Warning Red:     #FF3333    (Alert)
Dark Background: #0F1419    (Dark mode)
Light Gray:      #F5F5F5    (Light mode)
```

---

## 📍 Current Routes (Phase 1)

| Route | Screen | Purpose |
|-------|--------|---------|
| `/login` | LoginScreen | User authentication |
| `/register` | RegisterScreen | New account creation |
| `/` | HomeShellScreen | Authenticated home (placeholder) |

---

## 🧪 Test Cases (Phase 1)

### Invalid Login
- Email: `invalid` → Error: "Please enter a valid email"
- Password: `123` → Error: "Password must be at least 6 characters"

### Valid Login
- Email: `user@example.com`
- Password: `password123`

### Invalid Registration
- Full Name: `Jo` → Error: "Name must be at least 3 characters"
- Password: `Pass1` → Error: "Password must be at least 8 characters"
- Password: `password123` → Error: "Password must contain a special character"

### Valid Registration
- Full Name: `John Doe`
- Email: `john@example.com`
- Password: `SecureP@ss123`
- Confirm: `SecureP@ss123`
- Terms: ✓ Checked

---

## 🛠️ Development Commands

```bash
# Get dependencies
flutter pub get

# Run tests
flutter test

# Build runner for code generation
flutter pub run build_runner build

# Clean and rebuild
flutter clean && flutter pub get && flutter run

# Run with verbose output
flutter run -v

# Build for specific device
flutter run -d <device_id>
```

---

## 📦 Dependencies Reference

### Production
- **flutter_riverpod** - State management
- **go_router** - Navigation
- **supabase_flutter** - Backend
- **image_picker** - Media selection
- **flutter_secure_storage** - Secure storage
- **lucide_icons** - Icons
- **flutter_launcher_icons** - App icon
- **google_fonts** - Typography

### Development
- **build_runner** - Code generation
- **riverpod_generator** - Riverpod code gen

---

## 🔐 Security Checklist

✅ Email validation enabled  
✅ Strong password requirements  
✅ Password visibility toggle  
✅ Confirm password check  
✅ Terms acceptance required  
✅ Auto-generated avatars  
✅ Secure token storage ready  
✅ Supabase Auth enabled  
✅ RLS policies configured  
✅ User roles differentiated  

---

## 🐛 Common Issues & Solutions

### Issue: "Target of URI doesn't exist" error
**Solution:** Run `flutter pub get` to download dependencies

### Issue: App crashes on startup
**Solution:** Make sure Supabase credentials are set in `lib/config/supabase_config.dart`

### Issue: Database errors
**Solution:** Run SQL schema from `SUPABASE_SCHEMA.sql` in Supabase SQL editor

### Issue: Theme not changing
**Solution:** Restart the app or check device theme settings

---

## 📲 UI Navigation (Phase 1)

```
┌─────────────────────────┐
│      Login Screen       │
│  [Email input field]    │
│  [Password toggle]      │
│  [Sign In button]       │
│  [Create Account link]  │
└──────────────┬──────────┘
               │ "Create Account"
               ↓
┌─────────────────────────┐
│   Register Screen       │
│  [Full Name]            │
│  [Email]                │
│  [Password] (8+ chars)  │
│  [Confirm Password]     │
│  [Terms checkbox]       │
│  [Create button]        │
└──────────────┬──────────┘
               │ Success
               ↓
┌─────────────────────────┐
│   Home Shell (Auth)     │
│   Welcome, User!        │
│   [Logout button]       │
│   (Ready for Phase 2)   │
└─────────────────────────┘
```

---

## 🎓 Architecture Overview

### Layers
1. **UI Layer** - Screens and widgets (`lib/auth/screens/`, `lib/shared/widgets/`)
2. **State Layer** - Riverpod providers (`lib/auth/providers/`)
3. **Model Layer** - Data models (`lib/auth/models/`)
4. **Service Layer** - Business logic (`lib/core/providers/`, `lib/core/services/`)
5. **Config Layer** - App configuration (`lib/config/`)

### Data Flow
```
UI (Screen) 
  ↓ calls
Provider (Riverpod)
  ↓ uses
Service/Model
  ↓ communicates
Supabase Backend
```

---

## ✨ Next Phase Preview

**Phase 2: Shell & Navigation**
- Bottom Navigation with 5 tabs
- Custom drawer with profile
- ShellRoute implementation
- Tab persistence
- Logout functionality

---

## 📞 Support

For questions:
1. Check the relevant documentation file
2. Review the specific feature's code
3. Check PRD.md for requirements
4. Review SUPABASE_SCHEMA.sql for database structure

---

**Last Updated:** November 19, 2025  
**Version:** Phase 1 Complete  
**Status:** Ready for Phase 2 Command
