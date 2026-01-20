# Sports Hub - Deployment Guide

## Quick Start

### 1. Supabase Setup (5 minutes)

```bash
# Go to https://supabase.com and create account
# Create new project (choose free tier)

# Once project created:
# - Go to Settings → API
# - Copy Project URL
# - Copy anon (public) key
# - Save these to .env file
```

### 2. Database Initialization

1. Go to Supabase Dashboard → SQL Editor
2. Create new query
3. Copy all SQL from `docs/DATABASE_SCHEMA.sql`
4. Run query (⌘Enter)
5. Create another query and run `docs/RLS_POLICIES.sql`
6. Create Storage bucket:
   - Dashboard → Storage
   - Create bucket named `medical-documents`
   - Set to public

### 3. Local Development

```bash
# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Fill in Supabase credentials
# VITE_SUPABASE_URL=https://your-project.supabase.co
# VITE_SUPABASE_ANON_KEY=your-key-here

# Start dev server
npm run dev

# Opens at http://localhost:3000
```

### 4. Netlify Deployment

**Method 1: GitHub + Netlify UI (Easiest)**

```bash
# Push to GitHub
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/username/sports-hub.git
git push -u origin main
```

Then in Netlify:
1. Go to netlify.com → Connect to Git → GitHub
2. Select `sports-hub` repository
3. Configure:
   - Base directory: (leave empty)
   - Build command: `npm run build`
   - Publish directory: `dist`
4. Set environment variables:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
5. Click "Deploy"

**Method 2: Netlify CLI**

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login
netlify login

# Initialize site
netlify init

# Deploy
netlify deploy --prod

# View logs
netlify log
```

### 5. Test Deployment

1. Visit your Netlify domain
2. Go to `/src/pages/login.html`
3. Click "Register"
4. Create test account (admin role)
5. Test features:
   - Add player
   - Create training session
   - Check database in Supabase

---

## Environment Variables

### Development (.env)
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc...your-key...
VITE_APP_NAME=Sports Hub
```

### Production (Netlify UI)
Same as development - Netlify will inject at build time.

### Getting Credentials

1. Log in to Supabase
2. Project Settings → API
3. Under "Project API keys":
   - URL: `Project URL`
   - Key: `anon [public]`

---

## Troubleshooting

### "Connection refused" Error
- Check Supabase project is running
- Verify URL format: `https://xxxx.supabase.co`
- Check API key is for `anon` (public), not service role

### "Row Level Security violation"
- Check RLS policies are created (run RLS_POLICIES.sql)
- Verify user role in database matches expected role
- Check auth token is valid

### Data not showing in UI
- Check browser console for JavaScript errors
- Open DevTools → Network tab
- Verify Supabase calls are successful (200 status)
- Check user is signed in

### Netlify Build Fails
- Check `npm run build` works locally
- Verify all environment variables are set
- Check for missing dependencies in package.json
- View Netlify build logs for specific errors

---

## Post-Deployment Checklist

- [ ] Test login/register at `/src/pages/login.html`
- [ ] Create test users for each role (admin, coach, medical, player)
- [ ] Add test team and players
- [ ] Verify medical document upload works
- [ ] Test training session creation and attendance
- [ ] Confirm RLS prevents unauthorized access
- [ ] Check audit logs for a test action
- [ ] Test on mobile device
- [ ] Verify HTTPS is enforced
- [ ] Set up custom domain (optional)

---

## Security Checklist

✅ **RLS Policies Enabled**: All tables have RLS enabled
✅ **Auth Required**: All API calls require valid JWT
✅ **Role-Based Access**: Different permissions per role
✅ **Audit Logging**: All changes tracked in audit_logs
✅ **Secure Storage**: Medical documents not publicly listed
✅ **Environment Secrets**: API key never in source code
✅ **HTTPS**: Netlify enforces HTTPS automatically

---

## Monitoring & Maintenance

### Daily Checks
- Monitor error logs in browser console
- Check Supabase disk usage
- Review recent audit logs

### Weekly Checks
- Verify all team managers can access their data
- Test medical staff can upload documents
- Confirm player attendance is accurate

### Monthly Checks
- Backup Supabase database (export SQL)
- Review and archive old audit logs
- Update player statistics
- Clean up old events/trainings

---

## Scaling Tips

### As User Base Grows

1. **Enable Database Backups**
   - Supabase Dashboard → Backups
   - Enable daily backups

2. **Implement Caching**
   - Cache frequently accessed player lists
   - Use browser LocalStorage for user preferences

3. **Optimize Queries**
   - Add indexes on frequently filtered columns
   - Use views for complex aggregations

4. **Monitor Performance**
   - Supabase Dashboard → Network
   - Check query execution times

5. **Increase Limits**
   - Contact Supabase for higher rate limits
   - Upgrade to paid plan if needed

---

## Backup & Recovery

### Backup Supabase Data

```bash
# Export all tables as CSV
# Via Supabase Dashboard → Database → Tables → Export

# Or use pg_dump if you have PostgreSQL installed
pg_dump postgresql://user:password@host/database > backup.sql
```

### Restore from Backup

1. Go to Supabase Dashboard → SQL Editor
2. Create new query
3. Paste SQL from backup file
4. Run query

---

## Custom Domain (Optional)

1. Register domain (Namecheap, GoDaddy, etc)
2. In Netlify: Domain settings → Add custom domain
3. Update DNS records:
   - Type: `CNAME`
   - Name: `www`
   - Value: `your-site.netlify.app`
4. Add apex domain for root

---

## Getting Help

- **Supabase Community**: https://discord.supabase.com
- **Netlify Support**: https://support.netlify.com
- **Stack Overflow**: Tag with `supabase` or `netlify`

---

**Deployment complete! 🎉**

Your Sports Hub is now live and ready for thesis evaluation.

For API documentation, see `DOCUMENTATION.md`
For database schema, see `DATABASE_SCHEMA.sql`
