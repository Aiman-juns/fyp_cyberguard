# API Key Protection & Testing Guide

## 🔐 **3 Ways to Protect Your API Key During Testing**

### **Option 1: Testing Mode (RECOMMENDED FOR TESTING)**
Perfect when you want to test the app without using ANY API quota!

**Setup:**
1. Open your `.env` file
2. Add this line:
   ```
   AI_TESTING_MODE=true
   ```
3. Restart the app

**What happens:**
- ✅ All AI features work normally
- ✅ Uses smart mock responses (different for each type of message)
- ✅ NO API calls = NO quota usage
- ✅ Perfect for testing UI and flows
- ✅ Shows "🧪 TESTING MODE" in console

**When to use:**
- Testing the app functionality
- Demonstrating to others
- UI/UX development
- Any time you want to preserve API quota

---

### **Option 2: Backup API Key**
Have a second API key ready if the first one hits limits!

**Setup:**
1. Get a second API key from https://aistudio.google.com/app/apikey
2. Add to your `.env` file:
   ```
   GG_AI_KEY=your_primary_key_here
   GG_AI_KEY_BACKUP=your_backup_key_here
   ```
3. Restart the app

**What happens:**
- Primary key is used first
- If primary hits quota (429 error), automatically switches to backup
- Console shows: "⚠️ Primary API key failed, switching to backup key..."
- ✅ Now using backup API key

---

### **Option 3: Combination (BEST FOR DEMO DAY)**
Use testing mode normally, disable only when showing real AI!

**Setup:**
```env
# In your .env file:
GG_AI_KEY=your_primary_key
GG_AI_KEY_BACKUP=your_backup_key
AI_TESTING_MODE=true  # Keep this ON normally
```

**During demo:**
1. **Before demo:** Set `AI_TESTING_MODE=false` (uses real AI)
2. **After demo:** Set `AI_TESTING_MODE=true` (back to testing mode)

---

## 📊 **Error Messages You Might See**

### "API Quota Reached"
**What it means:** You've hit your daily/hourly limit

**Solutions shown in app:**
```
💡 Quick Fixes:
• Add AI_TESTING_MODE=true to your .env file (uses mock responses)
• Wait 15-30 minutes before trying again
• Add a backup API key: GG_AI_KEY_BACKUP=your_key
```

### "AI Service Busy (503)"
**What it means:** Google's servers are overloaded

**The app automatically:**
- Retries with exponential backoff (2s, 4s, 8s)
- Shows friendly message after 3 retries
- Suggests enabling testing mode

---

## 🧪 **Testing Mode Features**

### Smart Mock Responses:

**For SMS Analysis:**
- Messages with "http", "click", "verify" → Flagged as scam
- Messages with "password", "account" → Flagged as phishing
- Normal messages → Marked as safe

**For Password Checking:**
- Short passwords < 8 chars → Suggests making it longer
- Longer passwords → Encourages adding special chars

**For Chat Simulations:**
- Returns typical scammer responses
- Allows you to test the conversation flow

---

## 💡 **Best Practices**

### ✅ **DO:**
- Use testing mode during development
- Keep backup API key in `.env` file
- Never commit `.env` to git (it's in `.gitignore`)
- Use real API only when demoing to important people

### ❌ **DON'T:**
- Share your API keys publicly
- Commit API keys to GitHub
- Use real API for routine testing
- Panic if you hit quota limits (just enable testing mode!)

---

## 🚀 **Quick Commands**

### Enable Testing Mode:
```bash
# Add to .env:
echo "AI_TESTING_MODE=true" >> .env
```

### Disable Testing Mode:
```bash
# Edit .env and change to:
AI_TESTING_MODE=false
```

### Check Current Mode:
Look for console output when app starts:
- `🧪 AI TESTING MODE: Using mock responses (no API calls)` = Testing mode ON
- No special message = Using real API

---

## 📞 **Need Help?**

If you see errors:
1. Check console for detailed error messages
2. Try enabling testing mode first
3. Verify `.env` file is properly formatted
4. Make sure `.env` is loaded in `main.dart`

**Remember:** Testing mode is your friend! Use it liberally during development! 🎉
