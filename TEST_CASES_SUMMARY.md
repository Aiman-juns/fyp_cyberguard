# 📝 CyberGuard - Test Cases Summary Table

**Total Test Cases**: 116  
**Project**: CyberGuard - Cybersecurity Education App  
**Date**: January 8, 2026

---

## Test Cases Table

| Test Case ID | Description | Expected Result |
|-------------|-------------|-----------------|
| **AUTHENTICATION & AUTHORIZATION (12 Test Cases)** |||
| TC-AUTH-001 | User Registration - Valid Data | User account created successfully, auto-generated avatar assigned, redirected to dashboard |
| TC-AUTH-002 | User Registration - Weak Password | Error message displayed, registration prevented |
| TC-AUTH-003 | User Registration - Invalid Email Format | Validation error shown, registration prevented |
| TC-AUTH-004 | User Registration - Password Mismatch | Error message "Passwords do not match", registration prevented |
| TC-AUTH-005 | User Registration - Duplicate Email | Error message "Email already registered", registration prevented |
| TC-AUTH-006 | User Login - Valid Credentials | Login successful, user redirected to dashboard, session created |
| TC-AUTH-007 | User Login - Invalid Credentials | Error message "Invalid email or password", login prevented |
| TC-AUTH-008 | User Login - Empty Fields | Error messages displayed for empty fields, login prevented |
| TC-AUTH-009 | User Logout | User session terminated, redirected to login screen, secure storage cleared |
| TC-AUTH-010 | Session Persistence | User remains logged in after app restart, dashboard displayed without re-login |
| TC-AUTH-011 | Role-Based Access - Regular User | Access denied to admin features, user redirected to regular dashboard |
| TC-AUTH-012 | Role-Based Access - Admin User | Admin dashboard accessible, all admin features visible |
| **HOME DASHBOARD (9 Test Cases)** |||
| TC-HOME-001 | Home Screen Load | Quick stats displayed, daily challenge visible, security tip visible, all UI elements load properly |
| TC-HOME-002 | Quick Stats Accuracy | Stats accurately reflect user progress (completed, in-progress, XP) |
| TC-HOME-003 | Daily Challenge Card Display | Challenge card displays today's challenge with description and "Start Challenge" button |
| TC-HOME-004 | Daily Challenge - Complete | Challenge marked as completed, XP points awarded, completion indicator shown |
| TC-HOME-005 | Security Tip Rotation | Security tips rotate automatically or on click, different tips shown |
| TC-HOME-006 | Global Search Functionality | Search results displayed with relevant resources, news, and training modules |
| TC-HOME-007 | Quick Access Navigation | User navigated to correct screen with smooth transition animation |
| TC-HOME-008 | Custom Drawer Access | Drawer opens with user profile, navigation options, and logout option visible |
| TC-HOME-009 | Security FAB Functionality | Quick security options displayed, emergency support and breach checker accessible |
| **TRAINING HUB (14 Test Cases)** |||
| TC-TRAIN-001 | Training Hub Screen Load | Training hub displays with header, all modules visible, stats and daily challenge shown |
| TC-TRAIN-002 | Phishing Detection - Level Selection | Dialog shows 3 difficulty levels with descriptions, user can select any level |
| TC-TRAIN-003 | Phishing Detection - Beginner Level Completion | Questions displayed, correct answers marked, XP awarded, progress saved, confetti animation plays |
| TC-TRAIN-004 | Phishing Detection - Wrong Answer Handling | Incorrect answer marked, explanation shown, no XP for wrong answer |
| TC-TRAIN-005 | Password Dojo - Password Strength Test | Password rated as "Weak", suggestions provided, visual indicator shows low strength |
| TC-TRAIN-006 | Password Dojo - Strong Password Test | Password rated as "Strong/Very Strong", green visual indicator, positive feedback |
| TC-TRAIN-007 | Cyber Attack Analyst - Scenario Completion | Scenario described, multiple choice options, correct identification awards XP, explanation provided |
| TC-TRAIN-008 | Device Shield - Security Scan | Scan progress shown, security status displayed (Safe/Warning/Danger), recommendations provided |
| TC-TRAIN-009 | Infection Simulator - Safe Simulation | Simulation runs safely, visual representation shown, educational explanations provided |
| TC-TRAIN-010 | Adware Simulation - Ad Patterns | Fake ads appear safely, user learns to identify adware, removal instructions provided |
| TC-TRAIN-011 | Scam Simulator - Scam Recognition | Realistic scam scenarios presented, user identifies red flags, XP awarded for correct answers |
| TC-TRAIN-012 | Progress Persistence | Progress saved in Supabase, user can resume from where they left off |
| TC-TRAIN-013 | Recent Activity Display | Recent activities listed with module, level, result, XP earned, sorted by date |
| TC-TRAIN-014 | Question Review from Activity | Original question displayed, user's answer shown, correct answer and explanation provided |
| **GAMES MODULE (4 Test Cases)** |||
| TC-GAME-001 | Games Screen Load | Games screen displays with available games listed and descriptions visible |
| TC-GAME-002 | Hack Simulator - Launch | Game launches successfully with instructions and game interface loaded |
| TC-GAME-003 | Hack Simulator - Gameplay | Realistic hacking simulation, educational value maintained, score/XP awarded |
| TC-GAME-004 | Game Completion - XP Award | XP points awarded based on performance, points added to total, achievements unlocked |
| **AI ASSISTANT (7 Test Cases)** |||
| TC-AI-001 | Assistant Screen Load | Chat interface displayed, welcome message shown, input field and send button visible |
| TC-AI-002 | Send Simple Question | Question sent to Gemini AI, loading indicator shown, relevant AI response received |
| TC-AI-003 | Send Complex Cybersecurity Question | Detailed accurate response provided with actionable steps, formatted clearly |
| TC-AI-004 | Empty Message Handling | Message not sent, user prompted to enter text, no API call made |
| TC-AI-005 | Chat History Persistence | Chat history preserved after navigation, previous messages visible, conversation continues |
| TC-AI-006 | API Key Missing | Error message "AI service unavailable", user notified to configure API key, app doesn't crash |
| TC-AI-007 | Network Error Handling | Error message "No internet connection", app remains stable |
| **RESOURCES MODULE (6 Test Cases)** |||
| TC-RES-001 | Resources Screen Load | Resources list displayed, categories visible, search functionality available |
| TC-RES-002 | Resource Categories Display | Categories clearly labeled, resources filtered by category, category count accurate |
| TC-RES-003 | Resource Detail View | Resource detail screen opens, full content displayed, images/videos load properly |
| TC-RES-004 | Resource Search Functionality | Results filtered in real-time, relevant resources shown, no results message if empty |
| TC-RES-005 | Video Resource Playback | YouTube player loads, video plays smoothly, controls work, full-screen available |
| TC-RES-006 | Resource Bookmark/Save | Resource saved to bookmarks, accessible from saved section, can be unbookmarked |
| **NEWS MODULE (4 Test Cases)** |||
| TC-NEWS-001 | News Screen Load | News feed displayed, latest news shown first, cards show title, image, date, summary |
| TC-NEWS-002 | News Article View | News detail screen opens, full article content displayed, images load correctly |
| TC-NEWS-003 | News Refresh/Pull-to-Refresh | Refresh indicator shown, latest news fetched, feed updated with new articles |
| TC-NEWS-004 | News Share Functionality | Share options displayed, article shared successfully |
| **SECURITY TOOLS (4 Test Cases)** |||
| TC-TOOL-001 | Breach Checker - Valid Email Check | Email validated, breach check performed, results displayed with breach list if applicable |
| TC-TOOL-002 | Breach Checker - Invalid Email | Validation error shown, check not performed, user prompted for valid email |
| TC-TOOL-003 | Breach Checker - Known Breached Email | Warning shown, list of breaches displayed, recommendations and severity indicated |
| TC-TOOL-004 | Device Security Status Display | Device information shown, security status indicated, rooting/jailbreak detection, recommendations provided |
| **PERFORMANCE DASHBOARD (6 Test Cases)** |||
| TC-PERF-001 | Performance Screen Load | Performance dashboard displays, charts/graphs loaded, statistics shown, all data renders correctly |
| TC-PERF-002 | XP Points Display | XP count accurate, updates in real-time after completing activities |
| TC-PERF-003 | Achievement Display | Unlocked achievements shown with icons, locked achievements grayed out, progress towards achievements shown |
| TC-PERF-004 | Progress Charts | Charts display using FL Chart, data accurate and up-to-date, charts interactive, legend/labels clear |
| TC-PERF-005 | Module Completion Statistics | Each module shows completion percentage, completed/in-progress/not started counts accurate |
| TC-PERF-006 | Achievement Unlock Notification | Achievement unlock notification shown, confetti animation plays, achievement details displayed |
| **PROFILE MANAGEMENT (6 Test Cases)** |||
| TC-PROF-001 | Profile Screen Load | Profile screen displays, user avatar shown, name and email displayed, profile options visible |
| TC-PROF-002 | Edit Profile - Name Change | Name updated in Supabase, new name displayed immediately, confirmation message shown |
| TC-PROF-003 | Avatar Display | Avatar loaded from DiceBear API, avatar unique to user, displays clearly |
| TC-PROF-004 | Theme Toggle - Dark Mode | App switches to dark theme, all screens updated, preference saved, persists after restart |
| TC-PROF-005 | Theme Toggle - Light Mode | App switches to light theme, colors change appropriately, readability maintained |
| TC-PROF-006 | About Screen Access | About screen opens, app info displayed (version, name), developer info shown |
| **ADMIN DASHBOARD (8 Test Cases)** |||
| TC-ADMIN-001 | Admin Dashboard Access - Admin User | Admin dashboard accessible, all admin features visible, user management and analytics shown |
| TC-ADMIN-002 | Admin Dashboard Access - Regular User | Access denied, user redirected to regular dashboard, error message shown |
| TC-ADMIN-003 | Media Upload - Image | File picker opens, image selected, upload progress shown, uploaded to Supabase Storage successfully |
| TC-ADMIN-004 | Media Upload - Video | Video uploaded successfully, thumbnail generated, video accessible in resources |
| TC-ADMIN-005 | Resource Management - Edit | Resource editor opens, changes saved to database, resource updated immediately, confirmation shown |
| TC-ADMIN-006 | Resource Management - Delete | Confirmation dialog shown, resource deleted from database, removed from list, success message |
| TC-ADMIN-007 | User Management - View Users | All users listed, user info shown (name, email, registration date), user progress visible |
| TC-ADMIN-008 | Analytics Dashboard | User count displayed, active users shown, module completion rates shown, charts/graphs rendered |
| **NAVIGATION & ROUTING (6 Test Cases)** |||
| TC-NAV-001 | Bottom Navigation - Tab Switching | Each tab navigates correctly, active tab highlighted, smooth transitions, no lag |
| TC-NAV-002 | Deep Linking - Resource Detail | Resource detail screen loads with correct resource displayed, back navigation works |
| TC-NAV-003 | Deep Linking - News Detail | News detail screen loads with correct article displayed |
| TC-NAV-004 | Navigation - Back Button | Back navigation through screens works correctly, navigation stack maintained |
| TC-NAV-005 | Drawer Navigation | Each menu item navigates correctly, drawer closes after selection |
| TC-NAV-006 | 404 Error Page | Error page displayed, "Page not found" message shown, "Go Home" button available |
| **UI/UX TESTS (9 Test Cases)** |||
| TC-UI-001 | Splash Screen Display | Splash screen shows branding, tagline, shield icon, particle animations, 4-second duration |
| TC-UI-002 | Responsive Layout - Portrait | All elements fit on screen, no horizontal scrolling, text readable, buttons accessible |
| TC-UI-003 | Responsive Layout - Landscape | Layout adjusts appropriately, content remains accessible, no overflow issues |
| TC-UI-004 | Color Scheme - Light Theme | Primary colors used consistently, good contrast and readability |
| TC-UI-005 | Color Scheme - Dark Theme | Dark backgrounds used, light text for readability, sufficient contrast, eye-friendly colors |
| TC-UI-006 | Loading Indicators | Loading indicators shown, user aware of background processes, smooth animations, no frozen screens |
| TC-UI-007 | Error Messages - Visibility | Error messages clear and visible, warning icons used, messages user-friendly, actionable guidance |
| TC-UI-008 | Button Feedback | Visual feedback on tap (ripple effect), haptic feedback, button disabled state clear |
| TC-UI-009 | Animations - Smoothness | Animations smooth (60fps), no stuttering or lag, animations enhance UX |
| **SECURITY TESTS (8 Test Cases)** |||
| TC-SEC-001 | SQL Injection Protection | Injection prevented, Supabase RLS protects database, no unauthorized access |
| TC-SEC-002 | XSS Protection | Script not executed, input sanitized or escaped, no alert popup, safe display |
| TC-SEC-003 | Password Storage | Passwords hashed (not plaintext), Supabase Auth handles security, bcrypt or similar used |
| TC-SEC-004 | Session Token Security | Token stored in Flutter Secure Storage, token encrypted, not accessible by other apps |
| TC-SEC-005 | API Key Protection | API keys in .env file, .env in .gitignore, keys not hardcoded or visible in compiled app |
| TC-SEC-006 | Row-Level Security (RLS) | User cannot access other users' data, RLS policies enforce data isolation, unauthorized access denied |
| TC-SEC-007 | Rooted/Jailbroken Device Detection | Detection successful, warning displayed to user, user informed of security risks |
| TC-SEC-008 | Biometric Authentication | Biometric prompt shown, successful authentication grants access, failed authentication denies access |
| **PERFORMANCE & LOAD TESTS (6 Test Cases)** |||
| TC-PERF-101 | App Launch Time | Launch time < 3 seconds, splash screen smooth, no lag |
| TC-PERF-102 | Screen Transition Speed | Transitions < 300ms, smooth animations, no frame drops |
| TC-PERF-103 | Image Loading Performance | Images load progressively, placeholders shown while loading, no UI blocking, caching enabled |
| TC-PERF-104 | Database Query Performance | Query results < 2 seconds, pagination implemented if needed, no timeout errors |
| TC-PERF-105 | Memory Usage | Memory usage stable (no memory leaks), app doesn't grow excessively, no crashes |
| TC-PERF-106 | AI Response Time | Response received within 5 seconds, streaming response, timeout handling after 30 seconds |
| **EDGE CASES & ERROR HANDLING (7 Test Cases)** |||
| TC-EDGE-001 | Network Loss During Operation | Error message displayed, progress saved locally, graceful degradation, retry option available |
| TC-EDGE-002 | App Backgrounded During Training | Progress preserved, user returns to same question, no data loss |
| TC-EDGE-003 | Low Storage Space | Error message about low storage, operation gracefully fails, app doesn't crash |
| TC-EDGE-004 | Invalid API Responses | Error caught and handled, user-friendly message shown, app remains stable, retry option |
| TC-EDGE-005 | Concurrent User Actions | Buttons debounced, only one action processed, no duplicate submissions, no crashes |
| TC-EDGE-006 | Large Dataset Handling | Pagination or lazy loading implemented, smooth scrolling, no performance degradation |
| TC-EDGE-007 | Empty States | Empty state messages shown, guidance provided, no blank screens, call-to-action available |
| **INTEGRATION TESTS (6 Test Cases)** |||
| TC-INT-001 | Supabase Authentication Integration | All auth operations successful, tokens managed correctly, session maintained |
| TC-INT-002 | Supabase Database CRUD Operations | All CRUD operations successful, data persists correctly, RLS policies enforced |
| TC-INT-003 | Google Generative AI Integration | API call successful, response received, response formatted correctly, API errors handled |
| TC-INT-004 | YouTube Player Integration | YouTube player loads, video plays, controls functional |
| TC-INT-005 | DiceBear Avatar API | Avatar generated from DiceBear, avatar unique, avatar loads in profile |
| TC-INT-006 | FL Chart Integration | Charts render correctly, data visualized accurately, interactions smooth |
| **ACCESSIBILITY TESTS (4 Test Cases)** |||
| TC-ACC-001 | Screen Reader Compatibility | All elements have semantic labels, navigation clear and logical, interactive elements announced |
| TC-ACC-002 | Font Scaling | Text scales appropriately, no text cutoff, layout adjusts, readability maintained |
| TC-ACC-003 | Color Contrast (WCAG) | Contrast ratio meets WCAG AA standards (≥4.5:1 for normal text, ≥3:1 for large text) |
| TC-ACC-004 | Keyboard Navigation | Logical tab order, all interactive elements reachable, focus indicators visible |

---

## Summary Statistics

| Category | Number of Test Cases |
|----------|---------------------|
| Authentication & Authorization | 12 |
| Home Dashboard | 9 |
| Training Hub | 14 |
| Games Module | 4 |
| AI Assistant | 7 |
| Resources Module | 6 |
| News Module | 4 |
| Security Tools | 4 |
| Performance Dashboard | 6 |
| Profile Management | 6 |
| Admin Dashboard | 8 |
| Navigation & Routing | 6 |
| UI/UX Tests | 9 |
| Security Tests | 8 |
| Performance & Load Tests | 6 |
| Edge Cases & Error Handling | 7 |
| Integration Tests | 6 |
| Accessibility Tests | 4 |
| **TOTAL** | **116** |

---

## Priority Distribution

| Priority | Count | Percentage |
|----------|-------|------------|
| High | 65 | 56% |
| Medium | 42 | 36% |
| Low | 9 | 8% |

---

## Test Execution Checklist

- [ ] Authentication & Authorization (12 tests)
- [ ] Home Dashboard (9 tests)
- [ ] Training Hub (14 tests)
- [ ] Games Module (4 tests)
- [ ] AI Assistant (7 tests)
- [ ] Resources Module (6 tests)
- [ ] News Module (4 tests)
- [ ] Security Tools (4 tests)
- [ ] Performance Dashboard (6 tests)
- [ ] Profile Management (6 tests)
- [ ] Admin Dashboard (8 tests)
- [ ] Navigation & Routing (6 tests)
- [ ] UI/UX Tests (9 tests)
- [ ] Security Tests (8 tests)
- [ ] Performance & Load Tests (6 tests)
- [ ] Edge Cases & Error Handling (7 tests)
- [ ] Integration Tests (6 tests)
- [ ] Accessibility Tests (4 tests)

---

**Document Created**: January 8, 2026  
**Total Test Cases**: 116  
**Project**: CyberGuard - Cybersecurity Education App  
**Version**: 1.0
