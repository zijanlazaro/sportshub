# Disable Email Confirmation in Supabase

## Steps to Stop Email Confirmation:

1. **Go to your Supabase Dashboard**
   - Visit https://supabase.com/dashboard
   - Select your project

2. **Navigate to Authentication Settings**
   - Click "Authentication" in the left sidebar
   - Click "Settings" tab

3. **Disable Email Confirmations**
   - Find "Enable email confirmations" toggle
   - **Turn it OFF** (disable it)

4. **Set Site URL (Optional)**
   - Set "Site URL" to your domain (e.g., http://localhost:5173)
   - This prevents redirect issues

5. **Save Changes**
   - Click "Save" to apply settings

## Alternative: Use Custom SMTP (Advanced)
If you want more control, you can:
- Go to Authentication > Settings > SMTP Settings
- Configure custom SMTP or disable it entirely

After making these changes, new user registrations will not send confirmation emails and accounts will be immediately active.