/**
 * Supabase Client Configuration
 * Central hub for all database and auth operations
 */

import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://lfappbdxnfsomgtlhrhp.supabase.co'
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxmYXBwYmR4bmZzb21ndGxocmhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg5MDI0MzMsImV4cCI6MjA4NDQ3ODQzM30.EIlBtle-qQzBTLFRCDE5eL0LlzGBhJ06HQhYDaLiMOk';

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  throw new Error('Missing Supabase environment variables. Check .env file.');
}

/**
 * Create and export Supabase client instance
 */
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

/**
 * Get current authenticated user
 * @returns {Promise<Object|null>} Current user or null
 */
export async function getCurrentUser() {
  const { data: { user } } = await supabase.auth.getUser();
  return user;
}

/**
 * Get current user's role and profile data
 * @returns {Promise<Object|null>} User profile with role
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
 * @param {Function} callback - Called with (user, error) on auth state change
 * @returns {Function} Unsubscribe function
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
 * Sign up new user
 * @param {string} email
 * @param {string} password
 * @param {Object} userData - { full_name, role, team_id }
 * @returns {Promise<Object>} Auth response
 */
export async function signUp(email, password, userData) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password
  });

  if (error) throw error;

  // Create user profile
  if (data.user) {
    const { error: profileError } = await supabase.from('users').insert({
      id: data.user.id,
      email,
      full_name: userData.full_name,
      role: userData.role || 'player',
      team_id: userData.team_id || null
    });

    if (profileError) throw profileError;
  }

  return data;
}

/**
 * Sign in existing user
 * @param {string} email
 * @param {string} password
 * @returns {Promise<Object>} Auth response
 */
export async function signIn(email, password) {
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  });

  if (error) throw error;
  return data;
}

/**
 * Sign out current user
 * @returns {Promise<Object>} Sign out response
 */
export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

/**
 * Reset password via email
 * @param {string} email
 * @returns {Promise<Object>} Password reset response
 */
export async function resetPassword(email) {
  const { error } = await supabase.auth.resetPasswordForEmail(email);
  if (error) throw error;
}

/**
 * Update user password
 * @param {string} newPassword
 * @returns {Promise<Object>} Update response
 */
export async function updatePassword(newPassword) {
  const { error } = await supabase.auth.updateUser({
    password: newPassword
  });
  if (error) throw error;
}
