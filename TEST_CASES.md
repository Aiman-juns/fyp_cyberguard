# 🧪 CyberGuard - Comprehensive Test Cases

## Document Information
- **Project**: CyberGuard - Cybersecurity Education App
- **Platform**: Flutter (iOS & Android)
- **Version**: 1.0.0
- **Last Updated**: January 8, 2026
- **Test Type**: Functional, Integration, Security, Usability

---

## Table of Contents
1. [Authentication & Authorization Tests](#1-authentication--authorization-tests)
2. [Home Dashboard Tests](#2-home-dashboard-tests)
3. [Training Hub Tests](#3-training-hub-tests)
4. [Games Module Tests](#4-games-module-tests)
5. [AI Assistant Tests](#5-ai-assistant-tests)
6. [Resources Module Tests](#6-resources-module-tests)
7. [News Module Tests](#7-news-module-tests)
8. [Security Tools Tests](#8-security-tools-tests)
9. [Performance Dashboard Tests](#9-performance-dashboard-tests)
10. [Profile Management Tests](#10-profile-management-tests)
11. [Admin Dashboard Tests](#11-admin-dashboard-tests)
12. [Navigation & Routing Tests](#12-navigation--routing-tests)
13. [UI/UX Tests](#13-uiux-tests)
14. [Security Tests](#14-security-tests)
15. [Performance & Load Tests](#15-performance--load-tests)
16. [Edge Cases & Error Handling](#16-edge-cases--error-handling)
17. [Integration Tests](#17-integration-tests)
18. [Accessibility Tests](#18-accessibility-tests)

---

## 1. Authentication & Authorization Tests

### TC-AUTH-001: User Registration - Valid Data
- **Priority**: High
- **Type**: Functional
- **Precondition**: User is on registration screen
- **Test Steps**:
  1. Enter valid name (e.g., "John Doe")
  2. Enter valid email (e.g., "john.doe@example.com")
  3. Enter strong password (e.g., "SecureP@ss123")
  4. Re-enter same password in confirm field
  5. Click "Register" button
- **Expected Result**: 
  - User account created successfully
  - Auto-generated avatar assigned
  - User redirected to dashboard
  - Welcome message displayed
- **Status**: ⬜ Not Tested

### TC-AUTH-002: User Registration - Weak Password
- **Priority**: High
- **Type**: Functional
- **Precondition**: User is on registration screen
- **Test Steps**:
  1. Enter valid name
  2. Enter valid email
  3. Enter weak password (e.g., "pass" or "12345")
  4. Click "Register" button
- **Expected Result**: 
  - Error message: "Password must be at least 8 characters with numbers and symbols"
  - Registration prevented
  - User remains on registration screen
- **Status**: ⬜ Not Tested

### TC-AUTH-003: User Registration - Invalid Email Format
- **Priority**: High
- **Type**: Functional
- **Precondition**: User is on registration screen
- **Test Steps**:
  1. Enter valid name
  2. Enter invalid email (e.g., "invalidemail", "test@", "@example.com")
  3. Enter valid password
  4. Click "Register" button
- **Expected Result**: 
  - Error message: "Please enter a valid email address"
  - Registration prevented
- **Status**: ⬜ Not Tested

### TC-AUTH-004: User Registration - Password Mismatch
- **Priority**: High
- **Type**: Functional
- **Precondition**: User is on registration screen
- **Test Steps**:
  1. Enter valid name and email
  2. Enter password: "SecureP@ss123"
  3. Enter confirm password: "DifferentP@ss456"
  4. Click "Register" button
- **Expected Result**: 
  - Error message: "Passwords do not match"
  - Registration prevented
- **Status**: ⬜ Not Tested

### TC-AUTH-005: User Registration - Duplicate Email
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: Email already registered in system
- **Test Steps**:
  1. Enter name
  2. Enter already registered email
  3. Enter valid password
  4. Click "Register" button
- **Expected Result**: 
  - Error message: "Email already registered"
  - Registration prevented
- **Status**: ⬜ Not Tested

### TC-AUTH-006: User Login - Valid Credentials
- **Priority**: High
- **Type**: Functional
- **Precondition**: User has valid registered account
- **Test Steps**:
  1. Navigate to login screen
  2. Enter registered email
  3. Enter correct password
  4. Click "Login" button
- **Expected Result**: 
  - Login successful
  - User redirected to dashboard (or admin dashboard if admin)
  - User session created
- **Status**: ⬜ Not Tested

### TC-AUTH-007: User Login - Invalid Credentials
- **Priority**: High
- **Type**: Functional
- **Precondition**: User is on login screen
- **Test Steps**:
  1. Enter email: "test@example.com"
  2. Enter wrong password: "WrongPass123"
  3. Click "Login" button
- **Expected Result**: 
  - Error message: "Invalid email or password"
  - Login prevented
  - User remains on login screen
- **Status**: ⬜ Not Tested

### TC-AUTH-008: User Login - Empty Fields
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User is on login screen
- **Test Steps**:
  1. Leave email field empty
  2. Leave password field empty
  3. Click "Login" button
- **Expected Result**: 
  - Error messages displayed for empty fields
  - Login prevented
- **Status**: ⬜ Not Tested

### TC-AUTH-009: User Logout
- **Priority**: High
- **Type**: Functional
- **Precondition**: User is logged in
- **Test Steps**:
  1. Navigate to profile/drawer
  2. Click "Logout" button
  3. Confirm logout
- **Expected Result**: 
  - User session terminated
  - User redirected to login screen
  - Secure storage cleared
- **Status**: ⬜ Not Tested

### TC-AUTH-010: Session Persistence
- **Priority**: High
- **Type**: Functional
- **Precondition**: User is logged in
- **Test Steps**:
  1. Login to app
  2. Close app completely
  3. Reopen app after 5 minutes
- **Expected Result**: 
  - User remains logged in
  - Dashboard displayed without re-login
- **Status**: ⬜ Not Tested

### TC-AUTH-011: Role-Based Access - Regular User
- **Priority**: High
- **Type**: Functional
- **Precondition**: User logged in with regular user role
- **Test Steps**:
  1. Login as regular user
  2. Try to access admin dashboard
- **Expected Result**: 
  - Access denied to admin features
  - User redirected to regular dashboard
- **Status**: ⬜ Not Tested

### TC-AUTH-012: Role-Based Access - Admin User
- **Priority**: High
- **Type**: Functional
- **Precondition**: User logged in with admin role
- **Test Steps**:
  1. Login as admin user
  2. Access admin dashboard
- **Expected Result**: 
  - Admin dashboard accessible
  - All admin features visible
  - Media upload, user management available
- **Status**: ⬜ Not Tested

---

## 2. Home Dashboard Tests

### TC-HOME-001: Home Screen Load
- **Priority**: High
- **Type**: Functional
- **Precondition**: User is logged in
- **Test Steps**:
  1. Navigate to Home tab
- **Expected Result**: 
  - Quick stats displayed (completed modules, in-progress, XP)
  - Daily challenge card visible
  - Security tip card visible
  - All UI elements load properly
- **Status**: ⬜ Not Tested

### TC-HOME-002: Quick Stats Accuracy
- **Priority**: High
- **Type**: Functional
- **Precondition**: User has completed some training
- **Test Steps**:
  1. Complete 2 training modules
  2. Navigate to Home screen
  3. Check "Completed" stat
- **Expected Result**: 
  - Completed count shows "2"
  - Stats accurately reflect user progress
- **Status**: ⬜ Not Tested

### TC-HOME-003: Daily Challenge Card Display
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User is on home screen
- **Test Steps**:
  1. View daily challenge card
  2. Read challenge details
- **Expected Result**: 
  - Challenge card displays today's challenge
  - Challenge description visible
  - "Start Challenge" button present
- **Status**: ⬜ Not Tested

### TC-HOME-004: Daily Challenge - Complete
- **Priority**: High
- **Type**: Functional
- **Precondition**: Daily challenge available
- **Test Steps**:
  1. Click "Start Challenge" button
  2. Complete challenge successfully
  3. Return to home screen
- **Expected Result**: 
  - Challenge marked as completed
  - XP points awarded
  - Completion indicator shown
- **Status**: ⬜ Not Tested

### TC-HOME-005: Security Tip Rotation
- **Priority**: Low
- **Type**: Functional
- **Precondition**: User is on home screen
- **Test Steps**:
  1. View current security tip
  2. Wait or manually trigger tip change
  3. Observe new tip
- **Expected Result**: 
  - Security tips rotate automatically or on click
  - Different tips shown
  - Tips are relevant and educational
- **Status**: ⬜ Not Tested

### TC-HOME-006: Global Search Functionality
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User is on home screen
- **Test Steps**:
  1. Click search icon/button
  2. Enter search term (e.g., "phishing")
  3. View results
- **Expected Result**: 
  - Search results displayed
  - Results include resources, news, training modules
  - Results are relevant to search term
- **Status**: ⬜ Not Tested

### TC-HOME-007: Quick Access Navigation
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User is on home screen
- **Test Steps**:
  1. Click on any feature card (e.g., Training Hub)
  2. Verify navigation
- **Expected Result**: 
  - User navigated to correct screen
  - Smooth transition animation
- **Status**: ⬜ Not Tested

### TC-HOME-008: Custom Drawer Access
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User is on home screen
- **Test Steps**:
  1. Swipe right or click menu icon
  2. View drawer contents
- **Expected Result**: 
  - Drawer opens with user profile
  - Navigation options visible
  - Logout option available
- **Status**: ⬜ Not Tested

### TC-HOME-009: Security FAB Functionality
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User is on home screen
- **Test Steps**:
  1. Click floating action button (Security FAB)
  2. View options
- **Expected Result**: 
  - Quick security options displayed
  - Emergency support accessible
  - Breach checker accessible
- **Status**: ⬜ Not Tested

---

## 3. Training Hub Tests

### TC-TRAIN-001: Training Hub Screen Load
- **Priority**: High
- **Type**: Functional
- **Precondition**: User logged in
- **Test Steps**:
  1. Navigate to Training Hub
- **Expected Result**: 
  - Training hub displays with header
  - All training modules visible
  - Quick stats shown (completed, in-progress, XP)
  - Daily challenge visible
- **Status**: ⬜ Not Tested

### TC-TRAIN-002: Phishing Detection - Level Selection
- **Priority**: High
- **Type**: Functional
- **Precondition**: User on training hub
- **Test Steps**:
  1. Click "Phishing Detection" module
  2. View level selection dialog
- **Expected Result**: 
  - Dialog shows 3 difficulty levels (Beginner, Intermediate, Advanced)
  - Each level shows description
  - User can select any level
- **Status**: ⬜ Not Tested

### TC-TRAIN-003: Phishing Detection - Beginner Level Completion
- **Priority**: High
- **Type**: Functional
- **Precondition**: User selected beginner level
- **Test Steps**:
  1. Start beginner phishing module
  2. Answer all questions correctly
  3. Complete module
- **Expected Result**: 
  - Questions displayed one by one
  - Correct answers marked as correct
  - XP points awarded
  - Progress saved
  - Completion screen shown
  - Confetti animation plays
- **Status**: ⬜ Not Tested

### TC-TRAIN-004: Phishing Detection - Wrong Answer Handling
- **Priority**: High
- **Type**: Functional
- **Precondition**: User in phishing module
- **Test Steps**:
  1. Answer question incorrectly
  2. View feedback
- **Expected Result**: 
  - Incorrect answer marked
  - Explanation shown
  - No XP awarded for wrong answer
  - User can continue to next question
- **Status**: ⬜ Not Tested

### TC-TRAIN-005: Password Dojo - Password Strength Test
- **Priority**: High
- **Type**: Functional
- **Precondition**: User on Password Dojo screen
- **Test Steps**:
  1. Launch Password Dojo
  2. Enter weak password (e.g., "password")
  3. View strength analysis
- **Expected Result**: 
  - Password rated as "Weak"
  - Suggestions provided
  - Visual indicator shows low strength
- **Status**: ⬜ Not Tested

### TC-TRAIN-006: Password Dojo - Strong Password Test
- **Priority**: High
- **Type**: Functional
- **Precondition**: User on Password Dojo screen
- **Test Steps**:
  1. Enter strong password (e.g., "MyS3cur3P@ssw0rd!2024")
  2. View strength analysis
- **Expected Result**: 
  - Password rated as "Strong" or "Very Strong"
  - Green visual indicator
  - Positive feedback provided
- **Status**: ⬜ Not Tested

### TC-TRAIN-007: Cyber Attack Analyst - Scenario Completion
- **Priority**: High
- **Type**: Functional
- **Precondition**: User selected cyber attack module
- **Test Steps**:
  1. Start Cyber Attack Analyst module
  2. Read attack scenario
  3. Identify attack type
  4. Submit answer
- **Expected Result**: 
  - Scenario clearly described
  - Multiple choice options available
  - Correct identification awards XP
  - Explanation provided
- **Status**: ⬜ Not Tested

### TC-TRAIN-008: Device Shield - Security Scan
- **Priority**: High
- **Type**: Functional
- **Precondition**: User on Device Shield screen
- **Test Steps**:
  1. Click "Scan Device"
  2. Wait for scan completion
  3. View results
- **Expected Result**: 
  - Scan progress shown
  - Security status displayed (Safe/Warning/Danger)
  - Vulnerabilities listed (if any)
  - Recommendations provided
- **Status**: ⬜ Not Tested

### TC-TRAIN-009: Infection Simulator - Safe Simulation
- **Priority**: High
- **Type**: Functional
- **Precondition**: User on Infection Simulator screen
- **Test Steps**:
  1. Start infection simulation
  2. Observe virus behavior
  3. Complete simulation
- **Expected Result**: 
  - Simulation runs safely (no actual harm)
  - Visual representation of infection
  - Educational explanations shown
  - User learns virus behavior
- **Status**: ⬜ Not Tested

### TC-TRAIN-010: Adware Simulation - Ad Patterns
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User on Adware Simulation screen
- **Test Steps**:
  1. Start adware simulation
  2. Observe adware patterns
  3. Try to close ads
- **Expected Result**: 
  - Fake ads appear (safely)
  - User learns to identify adware
  - Instructions on removal provided
- **Status**: ⬜ Not Tested

### TC-TRAIN-011: Scam Simulator - Scam Recognition
- **Priority**: High
- **Type**: Functional
- **Precondition**: User on Scam Simulator screen
- **Test Steps**:
  1. Start scam simulation
  2. Review scam scenario
  3. Identify scam indicators
  4. Submit answers
- **Expected Result**: 
  - Realistic scam scenarios presented
  - User can identify red flags
  - Feedback on answers provided
  - XP awarded for correct identification
- **Status**: ⬜ Not Tested

### TC-TRAIN-012: Progress Persistence
- **Priority**: High
- **Type**: Functional
- **Precondition**: User completes training module
- **Test Steps**:
  1. Complete half of a training module
  2. Close app
  3. Reopen app and navigate back to module
- **Expected Result**: 
  - Progress saved in Supabase
  - User can resume from where they left off
  - Completed questions marked
- **Status**: ⬜ Not Tested

### TC-TRAIN-013: Recent Activity Display
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User has completed training activities
- **Test Steps**:
  1. View "Recent Activity" section on Training Hub
  2. Click "View All"
- **Expected Result**: 
  - Recent activities listed
  - Each activity shows: module, level, result, XP earned
  - Activities sorted by date (most recent first)
  - Can click activity to review
- **Status**: ⬜ Not Tested

### TC-TRAIN-014: Question Review from Activity
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User has completed questions
- **Test Steps**:
  1. Click on a past activity
  2. Review question and answer
- **Expected Result**: 
  - Original question displayed
  - User's answer shown
  - Correct answer shown
  - Explanation provided
- **Status**: ⬜ Not Tested

---

## 4. Games Module Tests

### TC-GAME-001: Games Screen Load
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User logged in
- **Test Steps**:
  1. Navigate to Games tab
- **Expected Result**: 
  - Games screen displays
  - Available games listed
  - Game descriptions visible
- **Status**: ⬜ Not Tested

### TC-GAME-002: Hack Simulator - Launch
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User on Games screen
- **Test Steps**:
  1. Click "Hack Simulator" game
  2. Start game
- **Expected Result**: 
  - Game launches successfully
  - Instructions displayed
  - Game interface loads
- **Status**: ⬜ Not Tested

### TC-GAME-003: Hack Simulator - Gameplay
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: Hack Simulator game started
- **Test Steps**:
  1. Follow hacking simulation steps
  2. Complete challenges
  3. Finish game
- **Expected Result**: 
  - Realistic hacking simulation
  - Educational value maintained
  - Score/XP awarded
  - Learning outcomes achieved
- **Status**: ⬜ Not Tested

### TC-GAME-004: Game Completion - XP Award
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User completes game
- **Test Steps**:
  1. Complete any game
  2. Check XP points
- **Expected Result**: 
  - XP points awarded based on performance
  - Points added to user total
  - Achievement unlocked (if applicable)
- **Status**: ⬜ Not Tested

---

## 5. AI Assistant Tests

### TC-AI-001: Assistant Screen Load
- **Priority**: High
- **Type**: Functional
- **Precondition**: User logged in with valid Gemini API key
- **Test Steps**:
  1. Navigate to AI Assistant tab
- **Expected Result**: 
  - Chat interface displayed
  - Welcome message shown
  - Input field and send button visible
- **Status**: ⬜ Not Tested

### TC-AI-002: Send Simple Question
- **Priority**: High
- **Type**: Functional
- **Precondition**: User on AI Assistant screen
- **Test Steps**:
  1. Type question: "What is phishing?"
  2. Click send button
  3. Wait for response
- **Expected Result**: 
  - Question sent to Gemini AI
  - Loading indicator shown
  - AI response received
  - Response displayed in chat
  - Response is relevant and accurate
- **Status**: ⬜ Not Tested

### TC-AI-003: Send Complex Cybersecurity Question
- **Priority**: High
- **Type**: Functional
- **Precondition**: User on AI Assistant screen
- **Test Steps**:
  1. Type: "How can I protect my Android device from ransomware?"
  2. Send question
- **Expected Result**: 
  - Detailed, accurate response provided
  - Response includes actionable steps
  - Response formatted clearly
- **Status**: ⬜ Not Tested

### TC-AI-004: Empty Message Handling
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User on AI Assistant screen
- **Test Steps**:
  1. Leave input field empty
  2. Click send button
- **Expected Result**: 
  - Message not sent
  - User prompted to enter text
  - No API call made
- **Status**: ⬜ Not Tested

### TC-AI-005: Chat History Persistence
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User has had conversation with AI
- **Test Steps**:
  1. Send multiple messages
  2. Navigate away from assistant
  3. Return to assistant
- **Expected Result**: 
  - Chat history preserved
  - Previous messages visible
  - Can continue conversation
- **Status**: ⬜ Not Tested

### TC-AI-006: API Key Missing
- **Priority**: High
- **Type**: Error Handling
- **Precondition**: .env file missing GG_AI_KEY
- **Test Steps**:
  1. Remove API key from .env
  2. Try to use AI assistant
- **Expected Result**: 
  - Error message: "AI service unavailable"
  - User notified to configure API key
  - App doesn't crash
- **Status**: ⬜ Not Tested

### TC-AI-007: Network Error Handling
- **Priority**: High
- **Type**: Error Handling
- **Precondition**: Device offline
- **Test Steps**:
  1. Turn off internet
  2. Send message to AI
- **Expected Result**: 
  - Error message: "No internet connection"
  - Message queued for later (optional)
  - App remains stable
- **Status**: ⬜ Not Tested

---

## 6. Resources Module Tests

### TC-RES-001: Resources Screen Load
- **Priority**: High
- **Type**: Functional
- **Precondition**: User logged in
- **Test Steps**:
  1. Navigate to Resources via home or menu
- **Expected Result**: 
  - Resources list displayed
  - Categories visible
  - Search functionality available
- **Status**: ⬜ Not Tested

### TC-RES-002: Resource Categories Display
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User on Resources screen
- **Test Steps**:
  1. View resource categories
  2. Click on a category
- **Expected Result**: 
  - Categories clearly labeled
  - Resources filtered by category
  - Category count accurate
- **Status**: ⬜ Not Tested

### TC-RES-003: Resource Detail View
- **Priority**: High
- **Type**: Functional
- **Precondition**: User on Resources screen
- **Test Steps**:
  1. Click on a resource
  2. View resource details
- **Expected Result**: 
  - Resource detail screen opens
  - Full content displayed
  - Images/videos load properly
  - Back navigation works
- **Status**: ⬜ Not Tested

### TC-RES-004: Resource Search Functionality
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User on Resources screen
- **Test Steps**:
  1. Enter search term in search bar
  2. View filtered results
- **Expected Result**: 
  - Results filtered in real-time
  - Relevant resources shown
  - No results message if nothing found
- **Status**: ⬜ Not Tested

### TC-RES-005: Video Resource Playback
- **Priority**: High
- **Type**: Functional
- **Precondition**: Resource contains YouTube video
- **Test Steps**:
  1. Open resource with video
  2. Click play on video
  3. Watch video
- **Expected Result**: 
  - YouTube player loads
  - Video plays smoothly
  - Controls work (play, pause, seek)
  - Full-screen option available
- **Status**: ⬜ Not Tested

### TC-RES-006: Resource Bookmark/Save (if implemented)
- **Priority**: Low
- **Type**: Functional
- **Precondition**: User viewing resource
- **Test Steps**:
  1. Click bookmark icon
  2. Navigate away
  3. Check saved resources
- **Expected Result**: 
  - Resource saved to bookmarks
  - Accessible from saved section
  - Can be unbookmarked
- **Status**: ⬜ Not Tested

---

## 7. News Module Tests

### TC-NEWS-001: News Screen Load
- **Priority**: High
- **Type**: Functional
- **Precondition**: User logged in
- **Test Steps**:
  1. Navigate to News screen
- **Expected Result**: 
  - News feed displayed
  - Latest news shown first
  - News cards show: title, image, date, summary
- **Status**: ⬜ Not Tested

### TC-NEWS-002: News Article View
- **Priority**: High
- **Type**: Functional
- **Precondition**: User on News screen
- **Test Steps**:
  1. Click on news article
  2. Read full article
- **Expected Result**: 
  - News detail screen opens
  - Full article content displayed
  - Images load correctly
  - Readable formatting
  - Publish date shown
- **Status**: ⬜ Not Tested

### TC-NEWS-003: News Refresh/Pull-to-Refresh
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User on News screen
- **Test Steps**:
  1. Pull down on news feed
  2. Release
- **Expected Result**: 
  - Refresh indicator shown
  - Latest news fetched from Supabase
  - Feed updated with new articles
- **Status**: ⬜ Not Tested

### TC-NEWS-004: News Share Functionality (if implemented)
- **Priority**: Low
- **Type**: Functional
- **Precondition**: User viewing news article
- **Test Steps**:
  1. Click share button
  2. Select sharing method
- **Expected Result**: 
  - Share options displayed
  - Article shared successfully
- **Status**: ⬜ Not Tested

---

## 8. Security Tools Tests

### TC-TOOL-001: Breach Checker - Valid Email Check
- **Priority**: High
- **Type**: Functional
- **Precondition**: User on Breach Checker screen
- **Test Steps**:
  1. Enter email address
  2. Click "Check" button
  3. Wait for results
- **Expected Result**: 
  - Email validated
  - Breach check performed
  - Results displayed (breached or safe)
  - If breached: list of breaches shown with dates
- **Status**: ⬜ Not Tested

### TC-TOOL-002: Breach Checker - Invalid Email
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User on Breach Checker screen
- **Test Steps**:
  1. Enter invalid email format
  2. Click "Check" button
- **Expected Result**: 
  - Validation error shown
  - Check not performed
  - User prompted to enter valid email
- **Status**: ⬜ Not Tested

### TC-TOOL-003: Breach Checker - Known Breached Email
- **Priority**: High
- **Type**: Functional
- **Precondition**: Using known breached test email
- **Test Steps**:
  1. Enter known breached email (e.g., test@example.com from known breach)
  2. Check results
- **Expected Result**: 
  - Warning shown
  - List of breaches displayed
  - Recommendations provided
  - Severity indicated
- **Status**: ⬜ Not Tested

### TC-TOOL-004: Device Security Status Display
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User accessed security tools
- **Test Steps**:
  1. View device security status
  2. Check displayed information
- **Expected Result**: 
  - Device information shown
  - Security status indicated
  - Rooting/jailbreak detection (if applicable)
  - Recommendations provided
- **Status**: ⬜ Not Tested

---

## 9. Performance Dashboard Tests

### TC-PERF-001: Performance Screen Load
- **Priority**: High
- **Type**: Functional
- **Precondition**: User logged in
- **Test Steps**:
  1. Navigate to Performance tab
- **Expected Result**: 
  - Performance dashboard displays
  - Charts/graphs loaded
  - Statistics shown
  - All data renders correctly
- **Status**: ⬜ Not Tested

### TC-PERF-002: XP Points Display
- **Priority**: High
- **Type**: Functional
- **Precondition**: User has earned XP
- **Test Steps**:
  1. View total XP on performance screen
  2. Compare with actual earned XP
- **Expected Result**: 
  - XP count accurate
  - Updates in real-time after completing activities
- **Status**: ⬜ Not Tested

### TC-PERF-003: Achievement Display
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User has unlocked achievements
- **Test Steps**:
  1. View achievements section
  2. Check unlocked achievements
- **Expected Result**: 
  - Unlocked achievements shown with icons
  - Locked achievements shown as grayed out
  - Achievement descriptions visible
  - Progress towards locked achievements shown
- **Status**: ⬜ Not Tested

### TC-PERF-004: Progress Charts
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User has training progress
- **Test Steps**:
  1. View progress charts/graphs
  2. Analyze data visualization
- **Expected Result**: 
  - Charts display using FL Chart library
  - Data accurate and up-to-date
  - Charts interactive (if applicable)
  - Legend/labels clear
- **Status**: ⬜ Not Tested

### TC-PERF-005: Module Completion Statistics
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User completed some modules
- **Test Steps**:
  1. View module completion breakdown
  2. Check percentages
- **Expected Result**: 
  - Each module shows completion percentage
  - Completed count accurate
  - In-progress count accurate
  - Not started count accurate
- **Status**: ⬜ Not Tested

### TC-PERF-006: Achievement Unlock Notification
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User about to unlock achievement
- **Test Steps**:
  1. Complete requirement for achievement
  2. Observe notification
- **Expected Result**: 
  - Achievement unlock notification shown
  - Confetti animation plays
  - Achievement details displayed
  - XP bonus awarded (if applicable)
- **Status**: ⬜ Not Tested

---

## 10. Profile Management Tests

### TC-PROF-001: Profile Screen Load
- **Priority**: High
- **Type**: Functional
- **Precondition**: User logged in
- **Test Steps**:
  1. Navigate to Profile tab
- **Expected Result**: 
  - Profile screen displays
  - User avatar shown
  - User name and email displayed
  - Profile options visible
- **Status**: ⬜ Not Tested

### TC-PROF-002: Edit Profile - Name Change
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User on profile screen
- **Test Steps**:
  1. Click "Edit" or name field
  2. Change name to "New Name"
  3. Save changes
- **Expected Result**: 
  - Name updated in Supabase
  - New name displayed immediately
  - Confirmation message shown
- **Status**: ⬜ Not Tested

### TC-PROF-003: Avatar Display
- **Priority**: Low
- **Type**: Functional
- **Precondition**: User has auto-generated avatar
- **Test Steps**:
  1. View profile avatar
  2. Check avatar loads
- **Expected Result**: 
  - Avatar loaded from DiceBear API
  - Avatar unique to user
  - Avatar displays clearly
- **Status**: ⬜ Not Tested

### TC-PROF-004: Theme Toggle - Dark Mode
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: App in light mode
- **Test Steps**:
  1. Navigate to profile/settings
  2. Toggle dark mode switch
- **Expected Result**: 
  - App switches to dark theme
  - All screens updated
  - Preference saved
  - Theme persists after app restart
- **Status**: ⬜ Not Tested

### TC-PROF-005: Theme Toggle - Light Mode
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: App in dark mode
- **Test Steps**:
  1. Toggle light mode switch
- **Expected Result**: 
  - App switches to light theme
  - Colors change appropriately
  - Readability maintained
- **Status**: ⬜ Not Tested

### TC-PROF-006: About Screen Access
- **Priority**: Low
- **Type**: Functional
- **Precondition**: User on profile screen
- **Test Steps**:
  1. Click "About" option
  2. View about screen
- **Expected Result**: 
  - About screen opens
  - App info displayed (version, name)
  - Developer info shown
  - Back navigation works
- **Status**: ⬜ Not Tested

---

## 11. Admin Dashboard Tests

### TC-ADMIN-001: Admin Dashboard Access - Admin User
- **Priority**: High
- **Type**: Functional
- **Precondition**: Logged in as admin
- **Test Steps**:
  1. Login with admin credentials
  2. Navigate to admin dashboard
- **Expected Result**: 
  - Admin dashboard accessible
  - All admin features visible
  - User management, media upload, analytics shown
- **Status**: ⬜ Not Tested

### TC-ADMIN-002: Admin Dashboard Access - Regular User
- **Priority**: High
- **Type**: Security
- **Precondition**: Logged in as regular user
- **Test Steps**:
  1. Try to access /admin route
- **Expected Result**: 
  - Access denied
  - User redirected to regular dashboard
  - Error message shown
- **Status**: ⬜ Not Tested

### TC-ADMIN-003: Media Upload - Image
- **Priority**: High
- **Type**: Functional
- **Precondition**: Admin on media upload screen
- **Test Steps**:
  1. Click "Upload Media"
  2. Select image file (JPG/PNG)
  3. Add title and description
  4. Upload
- **Expected Result**: 
  - File picker opens
  - Image selected
  - Upload progress shown
  - Image uploaded to Supabase Storage
  - Success message displayed
- **Status**: ⬜ Not Tested

### TC-ADMIN-004: Media Upload - Video
- **Priority**: High
- **Type**: Functional
- **Precondition**: Admin on media upload screen
- **Test Steps**:
  1. Select video file (MP4)
  2. Upload to resources
- **Expected Result**: 
  - Video uploaded successfully
  - Thumbnail generated (if applicable)
  - Video accessible in resources
- **Status**: ⬜ Not Tested

### TC-ADMIN-005: Resource Management - Edit
- **Priority**: High
- **Type**: Functional
- **Precondition**: Admin with existing resources
- **Test Steps**:
  1. Navigate to resource management
  2. Click edit on a resource
  3. Modify title/content
  4. Save changes
- **Expected Result**: 
  - Resource editor opens
  - Changes saved to database
  - Resource updated immediately
  - Confirmation shown
- **Status**: ⬜ Not Tested

### TC-ADMIN-006: Resource Management - Delete
- **Priority**: High
- **Type**: Functional
- **Precondition**: Admin with existing resources
- **Test Steps**:
  1. Select resource to delete
  2. Click delete button
  3. Confirm deletion
- **Expected Result**: 
  - Confirmation dialog shown
  - Resource deleted from database
  - Resource removed from list
  - Success message displayed
- **Status**: ⬜ Not Tested

### TC-ADMIN-007: User Management - View Users
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: Admin on user management screen
- **Test Steps**:
  1. View list of registered users
  2. Check user details
- **Expected Result**: 
  - All users listed
  - User info shown (name, email, registration date)
  - User progress visible
- **Status**: ⬜ Not Tested

### TC-ADMIN-008: Analytics Dashboard
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: Admin on analytics screen
- **Test Steps**:
  1. View analytics/statistics
  2. Check various metrics
- **Expected Result**: 
  - User count displayed
  - Active users shown
  - Module completion rates shown
  - Charts/graphs rendered
- **Status**: ⬜ Not Tested

---

## 12. Navigation & Routing Tests

### TC-NAV-001: Bottom Navigation - Tab Switching
- **Priority**: High
- **Type**: Functional
- **Precondition**: User on any tab
- **Test Steps**:
  1. Click each bottom navigation tab
  2. Verify navigation
- **Expected Result**: 
  - Each tab navigates correctly
  - Active tab highlighted
  - Smooth transitions
  - No lag or crashes
- **Status**: ⬜ Not Tested

### TC-NAV-002: Deep Linking - Resource Detail
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: Valid resource ID
- **Test Steps**:
  1. Navigate to /resource/:id
  2. Check screen loads
- **Expected Result**: 
  - Resource detail screen loads
  - Correct resource displayed
  - Back navigation works
- **Status**: ⬜ Not Tested

### TC-NAV-003: Deep Linking - News Detail
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: Valid news ID
- **Test Steps**:
  1. Navigate to /news/:id
- **Expected Result**: 
  - News detail screen loads
  - Correct article displayed
- **Status**: ⬜ Not Tested

### TC-NAV-004: Navigation - Back Button
- **Priority**: High
- **Type**: Functional
- **Precondition**: User navigated multiple screens
- **Test Steps**:
  1. Navigate: Home → Training → Module
  2. Press back button
  3. Press back again
- **Expected Result**: 
  - Back to Training screen
  - Back to Home screen
  - Navigation stack maintained
- **Status**: ⬜ Not Tested

### TC-NAV-005: Drawer Navigation
- **Priority**: Medium
- **Type**: Functional
- **Precondition**: User on home screen
- **Test Steps**:
  1. Open drawer
  2. Click different menu items
- **Expected Result**: 
  - Each menu item navigates correctly
  - Drawer closes after selection
- **Status**: ⬜ Not Tested

### TC-NAV-006: 404 Error Page
- **Priority**: Low
- **Type**: Functional
- **Precondition**: None
- **Test Steps**:
  1. Navigate to invalid route (e.g., /nonexistent)
- **Expected Result**: 
  - Error page displayed
  - "Page not found" message shown
  - "Go Home" button available
  - User can navigate back
- **Status**: ⬜ Not Tested

---

## 13. UI/UX Tests

### TC-UI-001: Splash Screen Display
- **Priority**: High
- **Type**: Functional
- **Precondition**: Fresh app launch
- **Test Steps**:
  1. Launch app
  2. Watch splash screen
- **Expected Result**: 
  - Splash screen shows "CyberGuard" branding
  - "Secure Every Step" tagline displayed
  - Shield icon/logo visible
  - Particle animations play
  - Duration: 4 seconds
  - Auto-navigate to login
- **Status**: ⬜ Not Tested

### TC-UI-002: Responsive Layout - Portrait
- **Priority**: High
- **Type**: UI/UX
- **Precondition**: Device in portrait mode
- **Test Steps**:
  1. View all major screens in portrait
  2. Check layouts
- **Expected Result**: 
  - All elements fit on screen
  - No horizontal scrolling
  - Text readable
  - Buttons accessible
- **Status**: ⬜ Not Tested

### TC-UI-003: Responsive Layout - Landscape
- **Priority**: Medium
- **Type**: UI/UX
- **Precondition**: Device rotated to landscape
- **Test Steps**:
  1. Rotate device to landscape
  2. View screens
- **Expected Result**: 
  - Layout adjusts appropriately
  - Content remains accessible
  - No overflow issues
- **Status**: ⬜ Not Tested

### TC-UI-004: Color Scheme - Light Theme
- **Priority**: Medium
- **Type**: UI/UX
- **Precondition**: App in light mode
- **Test Steps**:
  1. View all screens
  2. Check color consistency
- **Expected Result**: 
  - Primary Blue (#0066CC) used consistently
  - Success Green (#00CC66) for positive actions
  - Warning Red (#FF3333) for alerts
  - Good contrast and readability
- **Status**: ⬜ Not Tested

### TC-UI-005: Color Scheme - Dark Theme
- **Priority**: Medium
- **Type**: UI/UX
- **Precondition**: App in dark mode
- **Test Steps**:
  1. Enable dark mode
  2. View all screens
- **Expected Result**: 
  - Dark backgrounds used
  - Light text for readability
  - Sufficient contrast (WCAG compliant)
  - Eye-friendly colors
- **Status**: ⬜ Not Tested

### TC-UI-006: Loading Indicators
- **Priority**: Medium
- **Type**: UI/UX
- **Precondition**: Actions that require loading
- **Test Steps**:
  1. Perform actions like: login, API calls, database queries
  2. Observe loading states
- **Expected Result**: 
  - Loading indicators shown
  - User aware of background processes
  - Smooth animations
  - No frozen screens
- **Status**: ⬜ Not Tested

### TC-UI-007: Error Messages - Visibility
- **Priority**: High
- **Type**: UI/UX
- **Precondition**: Actions that trigger errors
- **Test Steps**:
  1. Trigger various errors (wrong password, network error, etc.)
  2. Read error messages
- **Expected Result**: 
  - Error messages clear and visible
  - Red color or warning icon used
  - Messages user-friendly (not technical jargon)
  - Actionable guidance provided
- **Status**: ⬜ Not Tested

### TC-UI-008: Button Feedback
- **Priority**: Low
- **Type**: UI/UX
- **Precondition**: User interacting with buttons
- **Test Steps**:
  1. Click/tap various buttons
  2. Observe feedback
- **Expected Result**: 
  - Visual feedback on tap (ripple effect, color change)
  - Haptic feedback (if applicable)
  - Button disabled state clear
  - No double-tap issues
- **Status**: ⬜ Not Tested

### TC-UI-009: Animations - Smoothness
- **Priority**: Medium
- **Type**: UI/UX
- **Precondition**: User navigating app
- **Test Steps**:
  1. Trigger animations (screen transitions, confetti, etc.)
  2. Observe performance
- **Expected Result**: 
  - Animations smooth (60fps)
  - No stuttering or lag
  - Animations enhance UX
  - Can be disabled if performance issue
- **Status**: ⬜ Not Tested

---

## 14. Security Tests

### TC-SEC-001: SQL Injection Protection
- **Priority**: High
- **Type**: Security
- **Precondition**: User input fields
- **Test Steps**:
  1. Enter SQL injection string in login: `' OR '1'='1`
  2. Try to login
- **Expected Result**: 
  - Injection prevented
  - Supabase RLS protects database
  - No unauthorized access
  - Error or invalid message shown
- **Status**: ⬜ Not Tested

### TC-SEC-002: XSS Protection
- **Priority**: High
- **Type**: Security
- **Precondition**: User input fields
- **Test Steps**:
  1. Enter script tag: `<script>alert('XSS')</script>`
  2. Submit in profile name or similar
- **Expected Result**: 
  - Script not executed
  - Input sanitized or escaped
  - No alert popup
  - Safe display of content
- **Status**: ⬜ Not Tested

### TC-SEC-003: Password Storage
- **Priority**: High
- **Type**: Security
- **Precondition**: User registration/login
- **Test Steps**:
  1. Register new user
  2. Check database (admin access)
  3. Verify password storage
- **Expected Result**: 
  - Passwords hashed (not plaintext)
  - Supabase Auth handles password security
  - Bcrypt or similar used
- **Status**: ⬜ Not Tested

### TC-SEC-004: Session Token Security
- **Priority**: High
- **Type**: Security
- **Precondition**: User logged in
- **Test Steps**:
  1. Login
  2. Check secure storage for token
  3. Verify token encryption
- **Expected Result**: 
  - Token stored in Flutter Secure Storage
  - Token encrypted
  - Token not accessible by other apps
- **Status**: ⬜ Not Tested

### TC-SEC-005: API Key Protection
- **Priority**: High
- **Type**: Security
- **Precondition**: .env file with API keys
- **Test Steps**:
  1. Check .env file handling
  2. Verify keys not exposed in code
- **Expected Result**: 
  - API keys in .env file
  - .env in .gitignore
  - Keys not hardcoded
  - Keys not visible in compiled app
- **Status**: ⬜ Not Tested

### TC-SEC-006: Row-Level Security (RLS)
- **Priority**: High
- **Type**: Security
- **Precondition**: Multiple users in system
- **Test Steps**:
  1. Login as User A
  2. Try to access User B's data
- **Expected Result**: 
  - User A cannot access User B's progress
  - RLS policies enforce data isolation
  - Unauthorized access denied
- **Status**: ⬜ Not Tested

### TC-SEC-007: Rooted/Jailbroken Device Detection
- **Priority**: Medium
- **Type**: Security
- **Precondition**: App running on rooted/jailbroken device
- **Test Steps**:
  1. Run app on rooted device
  2. Check security warning
- **Expected Result**: 
  - Detection successful (if safe_device package enabled)
  - Warning displayed to user
  - User informed of security risks
- **Status**: ⬜ Not Tested

### TC-SEC-008: Biometric Authentication (if enabled)
- **Priority**: Medium
- **Type**: Security
- **Precondition**: Device has biometric capability
- **Test Steps**:
  1. Enable biometric login
  2. Lock and reopen app
  3. Authenticate with fingerprint/face
- **Expected Result**: 
  - Biometric prompt shown
  - Successful authentication grants access
  - Failed authentication denies access
- **Status**: ⬜ Not Tested

---

## 15. Performance & Load Tests

### TC-PERF-101: App Launch Time
- **Priority**: Medium
- **Type**: Performance
- **Precondition**: Fresh app launch
- **Test Steps**:
  1. Close app completely
  2. Launch app
  3. Measure time to splash screen → login screen
- **Expected Result**: 
  - Launch time < 3 seconds
  - Splash screen smooth
  - No lag
- **Status**: ⬜ Not Tested

### TC-PERF-102: Screen Transition Speed
- **Priority**: Medium
- **Type**: Performance
- **Precondition**: User navigating app
- **Test Steps**:
  1. Navigate between screens
  2. Measure transition time
- **Expected Result**: 
  - Transitions < 300ms
  - Smooth animations
  - No frame drops
- **Status**: ⬜ Not Tested

### TC-PERF-103: Image Loading Performance
- **Priority**: Medium
- **Type**: Performance
- **Precondition**: Screens with multiple images
- **Test Steps**:
  1. Load Resources screen with images
  2. Observe loading
- **Expected Result**: 
  - Images load progressively
  - Placeholders shown while loading
  - No UI blocking
  - Caching enabled
- **Status**: ⬜ Not Tested

### TC-PERF-104: Database Query Performance
- **Priority**: High
- **Type**: Performance
- **Precondition**: Large dataset in Supabase
- **Test Steps**:
  1. Load Training Hub with many activities
  2. Measure load time
- **Expected Result**: 
  - Query results < 2 seconds
  - Pagination implemented (if needed)
  - No timeout errors
- **Status**: ⬜ Not Tested

### TC-PERF-105: Memory Usage
- **Priority**: Medium
- **Type**: Performance
- **Precondition**: App running for extended period
- **Test Steps**:
  1. Use app for 30 minutes
  2. Navigate all screens multiple times
  3. Check memory usage
- **Expected Result**: 
  - Memory usage stable (no memory leaks)
  - App doesn't grow excessively
  - No crashes from memory issues
- **Status**: ⬜ Not Tested

### TC-PERF-106: AI Response Time
- **Priority**: Medium
- **Type**: Performance
- **Precondition**: AI Assistant with internet
- **Test Steps**:
  1. Send question to AI
  2. Measure response time
- **Expected Result**: 
  - Response received within 5 seconds
  - Streaming response (if implemented)
  - Timeout handling after 30 seconds
- **Status**: ⬜ Not Tested

---

## 16. Edge Cases & Error Handling

### TC-EDGE-001: Network Loss During Operation
- **Priority**: High
- **Type**: Error Handling
- **Precondition**: Active internet connection
- **Test Steps**:
  1. Start training module
  2. Turn off internet mid-module
  3. Continue using app
- **Expected Result**: 
  - Error message displayed
  - Progress saved locally
  - Graceful degradation
  - Retry option available
- **Status**: ⬜ Not Tested

### TC-EDGE-002: App Backgrounded During Training
- **Priority**: Medium
- **Type**: Error Handling
- **Precondition**: User in middle of training
- **Test Steps**:
  1. Start training question
  2. Press home button (background app)
  3. Wait 5 minutes
  4. Reopen app
- **Expected Result**: 
  - Progress preserved
  - User returns to same question
  - No data loss
- **Status**: ⬜ Not Tested

### TC-EDGE-003: Low Storage Space
- **Priority**: Medium
- **Type**: Error Handling
- **Precondition**: Device with very low storage
- **Test Steps**:
  1. Try to download resource/video
  2. Attempt to cache data
- **Expected Result**: 
  - Error message about low storage
  - Operation gracefully fails
  - App doesn't crash
  - User guided to free space
- **Status**: ⬜ Not Tested

### TC-EDGE-004: Invalid API Responses
- **Priority**: High
- **Type**: Error Handling
- **Precondition**: Supabase returns error
- **Test Steps**:
  1. Simulate 500 error from backend
  2. Observe app behavior
- **Expected Result**: 
  - Error caught and handled
  - User-friendly message shown
  - App remains stable
  - Retry option provided
- **Status**: ⬜ Not Tested

### TC-EDGE-005: Concurrent User Actions
- **Priority**: Medium
- **Type**: Error Handling
- **Precondition**: User rapidly clicking
- **Test Steps**:
  1. Rapidly tap buttons multiple times
  2. Try to trigger race conditions
- **Expected Result**: 
  - Buttons debounced
  - Only one action processed
  - No duplicate submissions
  - No crashes
- **Status**: ⬜ Not Tested

### TC-EDGE-006: Large Dataset Handling
- **Priority**: Medium
- **Type**: Performance
- **Precondition**: User with 1000+ activities
- **Test Steps**:
  1. Load "View All Activity"
  2. Scroll through activities
- **Expected Result**: 
  - Pagination or lazy loading implemented
  - Smooth scrolling
  - No performance degradation
  - All data accessible
- **Status**: ⬜ Not Tested

### TC-EDGE-007: Empty States
- **Priority**: Low
- **Type**: UI/UX
- **Precondition**: New user with no data
- **Test Steps**:
  1. Login as new user
  2. Navigate to Performance, Recent Activity, etc.
- **Expected Result**: 
  - Empty state messages shown
  - Guidance provided (e.g., "Start training to see progress")
  - No blank screens
  - Call-to-action available
- **Status**: ⬜ Not Tested

---

## 17. Integration Tests

### TC-INT-001: Supabase Authentication Integration
- **Priority**: High
- **Type**: Integration
- **Precondition**: Supabase configured
- **Test Steps**:
  1. Register → Login → Logout
  2. Verify all Supabase Auth interactions
- **Expected Result**: 
  - All auth operations successful
  - Tokens managed correctly
  - Session maintained
- **Status**: ⬜ Not Tested

### TC-INT-002: Supabase Database CRUD Operations
- **Priority**: High
- **Type**: Integration
- **Precondition**: Database configured
- **Test Steps**:
  1. Create progress entry
  2. Read progress
  3. Update progress
  4. Delete progress (if applicable)
- **Expected Result**: 
  - All CRUD operations successful
  - Data persists correctly
  - RLS policies enforced
- **Status**: ⬜ Not Tested

### TC-INT-003: Google Generative AI Integration
- **Priority**: High
- **Type**: Integration
- **Precondition**: Valid Gemini API key
- **Test Steps**:
  1. Send message to AI
  2. Receive response
- **Expected Result**: 
  - API call successful
  - Response received
  - Response formatted correctly
  - API errors handled
- **Status**: ⬜ Not Tested

### TC-INT-004: YouTube Player Integration
- **Priority**: Medium
- **Type**: Integration
- **Precondition**: Resource with YouTube video
- **Test Steps**:
  1. Open resource with video
  2. Play video
- **Expected Result**: 
  - YouTube player loads
  - Video plays
  - Controls functional
- **Status**: ⬜ Not Tested

### TC-INT-005: DiceBear Avatar API
- **Priority**: Low
- **Type**: Integration
- **Precondition**: New user registration
- **Test Steps**:
  1. Register new user
  2. Check avatar generation
- **Expected Result**: 
  - Avatar generated from DiceBear
  - Avatar unique
  - Avatar loads in profile
- **Status**: ⬜ Not Tested

### TC-INT-006: FL Chart Integration
- **Priority**: Medium
- **Type**: Integration
- **Precondition**: Performance screen with data
- **Test Steps**:
  1. View performance charts
  2. Interact with charts
- **Expected Result**: 
  - Charts render correctly
  - Data visualized accurately
  - Interactions smooth
- **Status**: ⬜ Not Tested

---

## 18. Accessibility Tests

### TC-ACC-001: Screen Reader Compatibility
- **Priority**: Medium
- **Type**: Accessibility
- **Precondition**: Screen reader enabled (TalkBack/VoiceOver)
- **Test Steps**:
  1. Enable screen reader
  2. Navigate app using screen reader
- **Expected Result**: 
  - All elements have semantic labels
  - Navigation clear and logical
  - Interactive elements announced
  - Images have alt text
- **Status**: ⬜ Not Tested

### TC-ACC-002: Font Scaling
- **Priority**: Medium
- **Type**: Accessibility
- **Precondition**: Device with large font setting
- **Test Steps**:
  1. Set device font size to largest
  2. View all screens
- **Expected Result**: 
  - Text scales appropriately
  - No text cutoff
  - Layout adjusts
  - Readability maintained
- **Status**: ⬜ Not Tested

### TC-ACC-003: Color Contrast (WCAG)
- **Priority**: Medium
- **Type**: Accessibility
- **Precondition**: Both light and dark themes
- **Test Steps**:
  1. Test color contrast ratios
  2. Check against WCAG AA standards
- **Expected Result**: 
  - Contrast ratio ≥ 4.5:1 for normal text
  - Contrast ratio ≥ 3:1 for large text
  - Important elements clearly visible
- **Status**: ⬜ Not Tested

### TC-ACC-004: Keyboard Navigation (if applicable)
- **Priority**: Low
- **Type**: Accessibility
- **Precondition**: External keyboard connected
- **Test Steps**:
  1. Navigate using Tab key
  2. Activate using Enter/Space
- **Expected Result**: 
  - Logical tab order
  - All interactive elements reachable
  - Focus indicators visible
- **Status**: ⬜ Not Tested

---

## Test Execution Summary

### Test Statistics
- **Total Test Cases**: 150+
- **Passed**: 
- **Failed**: 
- **Blocked**: 
- **Not Tested**: 

### Priority Breakdown
- **High Priority**: ~80 test cases
- **Medium Priority**: ~55 test cases
- **Low Priority**: ~15 test cases

### Testing Phases
1. **Phase 1**: Authentication & Core Navigation (TC-AUTH, TC-NAV)
2. **Phase 2**: Main Features (TC-HOME, TC-TRAIN, TC-GAME, TC-AI)
3. **Phase 3**: Content Modules (TC-RES, TC-NEWS, TC-TOOL)
4. **Phase 4**: Admin & Management (TC-ADMIN, TC-PROF, TC-PERF)
5. **Phase 5**: Security & Performance (TC-SEC, TC-PERF-101+)
6. **Phase 6**: Edge Cases & Integration (TC-EDGE, TC-INT)
7. **Phase 7**: UI/UX & Accessibility (TC-UI, TC-ACC)

---

## Testing Tools & Environment

### Recommended Tools
- **Unit Testing**: Flutter Test framework
- **Widget Testing**: Flutter Widget Testing
- **Integration Testing**: Flutter Integration Testing
- **Manual Testing**: Physical devices + emulators
- **Performance**: Flutter DevTools, Android Profiler
- **Security**: OWASP Mobile Security Testing Guide
- **Accessibility**: Accessibility Scanner (Android), Accessibility Inspector (iOS)

### Test Devices
- **Android**: 
  - Emulator (API 30+)
  - Physical device (Samsung, Pixel, etc.)
- **iOS**: 
  - Simulator (iOS 14+)
  - Physical device (iPhone, iPad)

### Test Data
- **Test User**: test@example.com / TestPass123!
- **Admin User**: admin@cyberguard.com / AdminP@ss123
- **Test Resources**: Sample phishing emails, attack scenarios
- **Test Progress**: Preloaded training completion data

---

## Bug Reporting Template

```markdown
**Bug ID**: BUG-XXX
**Test Case**: TC-XXX-XXX
**Severity**: Critical / High / Medium / Low
**Priority**: Urgent / High / Medium / Low
**Status**: Open / In Progress / Resolved / Closed

**Description**: 
Brief description of the bug

**Steps to Reproduce**:
1. Step 1
2. Step 2
3. Step 3

**Expected Result**: 
What should happen

**Actual Result**: 
What actually happened

**Screenshots/Videos**: 
Attach if applicable

**Environment**:
- Device: 
- OS Version: 
- App Version: 
- Network: WiFi / Mobile Data

**Additional Notes**: 
Any other relevant information
```

---

## Glossary

- **RLS**: Row-Level Security (Supabase database security)
- **XP**: Experience Points (gamification)
- **API**: Application Programming Interface
- **CRUD**: Create, Read, Update, Delete
- **FAB**: Floating Action Button
- **WCAG**: Web Content Accessibility Guidelines
- **UI**: User Interface
- **UX**: User Experience

---

## Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-08 | Test Team | Initial comprehensive test cases created |

---

**End of Test Cases Document**

Total Test Cases: 150+
Coverage: Authentication, Features, Security, Performance, Integration, Accessibility
Status: Ready for Test Execution
