/**
 * Supabase Client Configuration
 * Central hub for all database and auth operations - NO EMAIL CONFIRMATION
 */

// Wait for window.supabase to be available
if (typeof window.supabase === 'undefined') {
  throw new Error('Supabase CDN not loaded. Make sure to include the script tag.');
}

const { createClient } = window.supabase;

const SUPABASE_URL = 'https://guyppjhpjfzrfxldltjz.supabase.co'
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd1eXBwamhwamZ6cmZ4bGRsdGp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg5MDI1OTIsImV4cCI6MjA4NDQ3ODU5Mn0.6hUP3Ur2FYxBtZCb8SYz1cWq8VnIuzhdxvT1-tAtIC4';

/**
 * Create and export Supabase client instance
 */
window.supabaseClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

/**
 * Get current authenticated user
 */
window.getCurrentUser = async function() {
  const { data: { user } } = await window.supabaseClient.auth.getUser();
  return user;
}

/**
 * Get current user's role and profile data
 */
window.getCurrentUserProfile = async function() {
  const user = await window.getCurrentUser();
  if (!user) return null;

  const { data } = await window.supabaseClient
    .from('users')
    .select('*')
    .eq('id', user.id)
    .single();

  return data;
}

/**
 * Subscribe to authentication state changes
 */
window.onAuthStateChange = function(callback) {
  const { data: { subscription } } = window.supabaseClient.auth.onAuthStateChange(
    (event, session) => {
      callback(session?.user || null);
    }
  );
  return () => subscription?.unsubscribe();
}

/**
 * Sign up new user - NO EMAIL CONFIRMATION
 */
window.signUp = async function(email, password, userData) {
  const { data, error } = await window.supabaseClient.auth.signUp({
    email,
    password,
    options: {
      emailRedirectTo: undefined // Disable email confirmation
    }
  });

  if (error) throw error;

  // Create user profile immediately
  if (data.user) {
    const { error: profileError } = await window.supabaseClient.from('users').insert({
      id: data.user.id,
      email,
      role: userData.role || 'player',
      team_id: userData.team_id || null,
      active: true
    });

    if (profileError) throw profileError;
  }

  return data;
}

/**
 * Sign in existing user
 */
window.signIn = async function(email, password) {
  const { data, error } = await window.supabaseClient.auth.signInWithPassword({
    email,
    password
  });

  if (error) throw error;

  // Update last login
  if (data.user) {
    await window.supabaseClient.from('users')
      .update({ last_login: new Date().toISOString() })
      .eq('id', data.user.id);
  }

  return data;
}

/**
 * Sign out current user
 */
window.signOut = async function() {
  const { error } = await window.supabaseClient.auth.signOut();
  if (error) throw error;
}

/**
 * Reset password via email
 */
window.resetPassword = async function(email) {
  const { error } = await window.supabaseClient.auth.resetPasswordForEmail(email);
  if (error) throw error;
}

/**
 * Update user password
 */
window.updatePassword = async function(newPassword) {
  const { error } = await window.supabaseClient.auth.updateUser({
    password: newPassword
  });
  if (error) throw error;
}
