/**
 * Profile Management Module
 * Handle user profile CRUD operations
 */

import { supabase } from './supabaseClient.js';

/**
 * Get user profile by user ID with session validation
 */
export async function getUserProfile(userId) {
  // Verify user is authenticated
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    throw new Error('Authentication required');
  }

  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', userId)
    .single();

  if (error) {
    // If profile doesn't exist, create a basic one
    if (error.code === 'PGRST116') {
      const { data: newProfile, error: insertError } = await supabase
        .from('users')
        .insert({
          id: userId,
          email: user.email,
          role: 'player',
          active: true,
          created_at: new Date().toISOString()
        })
        .select()
        .single();
      
      if (insertError) throw insertError;
      return newProfile;
    }
    throw error;
  }
  return data;
}

/**
 * Update user profile with session validation
 */
export async function updateUserProfile(userId, profileData) {
  // Verify user is authenticated
  const { data: { user } } = await supabase.auth.getUser();
  if (!user || user.id !== userId) {
    throw new Error('Authentication required or user mismatch');
  }

  const { data, error } = await supabase
    .from('users')
    .update({
      first_name: profileData.first_name,
      last_name: profileData.last_name,
      middle_name: profileData.middle_name || null,
      suffix: profileData.suffix || null,
      role: profileData.role,
      team_id: profileData.team_id || null,
      updated_at: new Date().toISOString()
    })
    .eq('id', userId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Get all teams for selection
 */
export async function getAllTeams() {
  const { data, error } = await supabase
    .from('teams')
    .select('id, name, sport')
    .order('name');

  if (error) throw error;
  return data;
}

/**
 * Create a new team
 */
export async function createTeam(teamData) {
  const { data, error } = await supabase
    .from('teams')
    .insert({
      name: teamData.name,
      sport: teamData.sport,
      season: teamData.season || '2024',
      active: true
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Update team
 */
export async function updateTeam(teamId, teamData) {
  const { data, error } = await supabase
    .from('teams')
    .update({
      name: teamData.name,
      sport: teamData.sport,
      season: teamData.season,
      active: teamData.active,
      updated_at: new Date().toISOString()
    })
    .eq('id', teamId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Delete team
 */
export async function deleteTeam(teamId) {
  const { error } = await supabase
    .from('teams')
    .delete()
    .eq('id', teamId);

  if (error) throw error;
}