# Sports Hub - Setup Instructions

## 🎯 Complete Setup Guide for Sports Hub

### System Requirements
- **Node.js**: 16.0.0 or higher
- **npm**: 7.0.0 or higher
- Modern web browser (Chrome, Firefox, Safari, Edge)
- Internet connection (for Supabase & Netlify)

---

## Phase 1: Supabase Setup (10 minutes)

### Step 1.1: Create Supabase Project
1. Go to [https://supabase.com](https://supabase.com)
2. Click "Start your project"
3. Sign up with email or GitHub
4. Create organization (give it a name)
5. Create new project:
   - **Name**: `sports-hub`
   - **Database Password**: Save securely
   - **Region**: Choose nearest to you
   - **Pricing Plan**: `Free` tier
6. Wait for project to initialize (~5 minutes)

### Step 1.2: Get Credentials
1. Go to Project Settings (⚙️ icon)
2. Click "API" tab
3. Copy these values:
   - **Project URL** (under "Project URL")
   - **Anon Key** (under "Project API keys" → "anon [public]")
4. Save both values

### Step 1.3: Create Database Tables
1. From main dashboard, click "SQL Editor"
2. Click "New Query"
3. Open file: `docs/DATABASE_SCHEMA.sql`
4. Copy all SQL code
5. Paste into Supabase SQL Editor
6. Click "Run" button (or press Ctrl+Enter)
7. Wait for success message
8. Create another new query
9. Repeat with `docs/RLS_POLICIES.sql`
10. Click "Run"

### Step 1.4: Create Storage Bucket
1. Click "Storage" in left sidebar
2. Click "New bucket"
3. **Name**: `medical-documents`
4. **Public bucket**: Toggle ON
5. Click "Create bucket"
6. Inside bucket, click "Policies" tab
7. Click "New policy" → "For queries only"
8. Leave default settings, click "Review"
9. Click "Save policy"

✅ **Supabase is ready!**

---

## Phase 2: Local Project Setup (5 minutes)

### Step 2.1: Clone Repository
```bash
# Navigate to desired folder
cd path/to/your/projects

# Clone the repository
git clone https://github.com/your-username/sports-hub.git

# Enter directory
cd sports-hub
```

### Step 2.2: Install Dependencies
```bash
# Install Node dependencies
npm install

# Verify installation
npm --version  # Should be 7+
node --version # Should be 16+
```

### Step 2.3: Configure Environment
```bash
# Copy example env file
cp .env.example .env

# Edit .env file (use your favorite editor)
# VITE_SUPABASE_URL=https://your-project-id.supabase.co
# VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

**Example .env:**
```env
VITE_SUPABASE_URL=https://abcdef123456.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
VITE_APP_NAME=Sports Hub
VITE_APP_VERSION=1.0.0
```

### Step 2.4: Start Development Server
```bash
# Start local server
npm run dev

# Output should show:
# ➜  Local:   http://localhost:3000/

# Open browser to http://localhost:3000
```

✅ **Application is running locally!**

---

## Phase 3: Test the Application (10 minutes)

### Step 3.1: Test Registration
1. Go to http://localhost:3000/src/pages/login.html
2. Click "Register" tab
3. Fill form:
   - **Full Name**: Test Admin
   - **Email**: admin@test.com
   - **Role**: Admin
   - **Password**: TestPass123!
   - **Confirm**: TestPass123!
4. Click "Create Account"
5. Check for success message

### Step 3.2: Test Login
1. Click "Login" tab
2. Enter credentials:
   - **Email**: admin@test.com
   - **Password**: TestPass123!
3. Click "Sign In"
4. Should redirect to dashboard

### Step 3.3: Test Dashboard
1. Verify you see dashboard
2. Check user name appears
3. Click navigation items:
   - Players
   - Training
   - Medical
   - Schedule
4. Verify no JavaScript errors in console

### Step 3.4: Add Test Player
1. Click "Players" nav item
2. Click "+ Add Player" button
3. Fill form with test data
4. Click submit
5. Verify player appears in table

✅ **Core functionality verified!**

---

## Phase 4: Deploy to Netlify (15 minutes)

### Option A: GitHub + Netlify UI (Easiest)

#### Step 4A.1: Create GitHub Repository
```bash
cd sports-hub

# Initialize git
git init

# Add all files
git add .

# Create commit
git commit -m "Initial Sports Hub commit"

# Add remote
git remote add origin https://github.com/YOUR-USERNAME/sports-hub.git

# Push to GitHub
git branch -M main
git push -u origin main
```

#### Step 4A.2: Connect to Netlify
1. Go to [https://netlify.com](https://netlify.com)
2. Sign up / Login
3. Click "Add new site" → "Import an existing project"
4. Select GitHub
5. Authorize Netlify with GitHub
6. Select `sports-hub` repository
7. Configure build settings:
   - **Base directory**: (leave empty)
   - **Build command**: `npm run build`
   - **Publish directory**: `dist`
8. Click "Show advanced"
9. Click "New variable"
10. Add environment variables:
    - **Name**: `VITE_SUPABASE_URL`, **Value**: `https://your-project.supabase.co`
    - **Name**: `VITE_SUPABASE_ANON_KEY`, **Value**: `your-anon-key`
11. Click "Deploy site"
12. Wait ~2 minutes for deployment

#### Step 4A.3: View Live Site
1. Netlify shows deployment progress
2. Once complete, shows site URL
3. Click URL to visit live site
4. Test login at `/src/pages/login.html`

### Option B: Netlify CLI

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login to Netlify
netlify login

# Initialize site
netlify init
# Follow prompts:
# - Build command: npm run build
# - Publish directory: dist

# Deploy to production
netlify deploy --prod

# Get site URL from output
```

✅ **Application deployed to production!**

---

## Phase 5: Verification Checklist

### Functionality Tests
- [ ] Can register new users
- [ ] Can login with created account
- [ ] Dashboard loads without errors
- [ ] Can add new player
- [ ] Can view player list
- [ ] Role is displayed correctly
- [ ] Can logout and re-login

### Security Tests
- [ ] Cannot access dashboard without login
- [ ] Cannot access medical records as player role (if not assigned)
- [ ] Browser shows HTTPS (if on Netlify)
- [ ] Audit logs are created (check Supabase)

### Performance Tests
- [ ] Page loads in < 3 seconds
- [ ] No console errors
- [ ] Mobile layout is responsive
- [ ] Images load properly

### Deployment Tests
- [ ] Live site URL works
- [ ] Can deploy code updates
- [ ] Environment variables are secure
- [ ] Database is accessible from production

---

## Troubleshooting

### "Cannot find module '@supabase/supabase-js'"
```bash
npm install @supabase/supabase-js
```

### "VITE_SUPABASE_URL is undefined"
- Check .env file exists in root directory
- Verify variable names exactly match
- Restart dev server: `npm run dev`

### "Supabase connection failed"
- Check internet connection
- Verify Project URL format (should be https://xxx.supabase.co)
- Check anon key is copied correctly
- Try in Supabase dashboard directly

### "RLS policy violation"
- Verify all RLS policies are created
- Check user role is set in database
- Check user is authenticated (auth.uid() not null)
- Review specific policy error message

### "Page styling looks wrong"
- Check Tailwind CSS is working
- Clear browser cache (Ctrl+Shift+Delete)
- Rebuild CSS: `npm run build`
- Check `tailwind.config.js` is configured

---

## Next Steps

### After Setup
1. Read `DOCUMENTATION.md` for complete API reference
2. Explore database schema in `DATABASE_SCHEMA.sql`
3. Create test users for each role
4. Add test data (teams, players, training sessions)
5. Test role-based access with different user roles

### For Thesis Submission
1. Prepare system explanation document
2. Include screenshots of working application
3. Document database schema
4. Explain security implementation
5. Include performance metrics
6. Provide deployment instructions

### For Production
1. Set up database backups (Supabase → Backups)
2. Configure custom domain
3. Set up monitoring alerts
4. Create user documentation
5. Plan scalability upgrades

---

## Quick Reference Commands

```bash
# Development
npm install          # Install dependencies
npm run dev         # Start dev server
npm run build       # Build for production
npm run preview     # Preview production build

# Git
git add .           # Stage all changes
git commit -m "msg" # Create commit
git push            # Push to GitHub

# Database
# Run SQL in Supabase SQL Editor
# Run DATABASE_SCHEMA.sql first
# Then run RLS_POLICIES.sql
```

---

## Support Resources

| Resource | URL |
|----------|-----|
| Supabase Docs | https://supabase.com/docs |
| Netlify Docs | https://docs.netlify.com |
| Tailwind CSS | https://tailwindcss.com/docs |
| JavaScript MDN | https://developer.mozilla.org/en-US/docs/Web/JavaScript |
| Git Guide | https://github.com/git-tips/tips |

---

## Success Indicators

✅ You have successfully set up Sports Hub when:
1. Development server runs locally at http://localhost:3000
2. Can register and login
3. Dashboard displays without errors
4. Can add players to database
5. Application is live on Netlify
6. All features are accessible per role

---

**Congratulations! 🎉 Sports Hub is now ready for development and thesis submission!**

For questions or issues, refer to the complete documentation in `docs/DOCUMENTATION.md`
