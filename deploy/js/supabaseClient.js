/**
 * Supabase Client Configuration
 * Central hub for all database and auth operations - NO EMAIL CONFIRMATION
 */

import { createClient } from 'https://cdn.skypack.dev/@supabase/supabase-js';

const SUPABASE_URL = 'https://guyppjhpjfzrfxldltjz.supabase.co'
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd1eXBwamhwamZ6cmZ4bGRsdGp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg5MDI1OTIsImV4cCI6MjA4NDQ3ODU5Mn0.6hUP3Ur2FYxBtZCb8SYz1cWq8VnIuzhdxvT1-tAtIC4';

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  throw new Error('Missing Supabase environment variables. Check .env file.');
}

/**
 * Create and export Supabase client instance
 */
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

/**
 * Get current authenticated user
 */
export async function getCurrentUser() {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

/**
 * Get current user's role and profile data
 */
export async function getCurrentUserProfile() {
  const user = await getCurrentUser();
  if (!user) return null;

  const { data } = await supabase
    .from('users')
    .select('*')
    .eq('id', user.id)
    .single();

  return data;
}

/**
 * Subscribe to authentication state changes
 */
export function onAuthStateChange(callback) {
  const { data: { subscription } } = supabase.auth.onAuthStateChange(
    (event, session) => {
      callback(session?.user || null);
    }
  );
  return () => subscription?.unsubscribe();
}

/**
 * Sign up new user - NO EMAIL CONFIRMATION
 */
export async function signUp(email, password, userData) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      emailRedirectTo: undefined // Disable email confirmation
    }
  });

  if (error) throw error;

  // Create user profile immediately
  if (data.user) {
    const { error: profileError } = await supabase.from('users').insert({
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
export async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  });

  if (error) throw error;

  // Update last login
  if (data.user) {
    await supabase.from('users')
      .update({ last_login: new Date().toISOString() })
      .eq('id', data.user.id);
  }

  return data;
}

/**
 * Sign out current user
 */
export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

/**
 * Reset password via email
 */
export async function resetPassword(email) {
  const { error } = await supabase.auth.resetPasswordForEmail(email);
  if (error) throw error;
}

/**
 * Update user password
 */
export async function updatePassword(newPassword) {
  const { error } = await supabase.auth.updateUser({
    password: newPassword
  });
  if (error) throw error;
}
