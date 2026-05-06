/**
 * Profile Management Module
 * Handle user profile CRUD operations
 */

import { supabase } from './supabaseClient.js';
import { debouncedRefreshTeamData, debouncedRefreshDashboardData } from './teamRefresh.js';

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

  // If user is a coach, handle team coach assignments properly
  if (profileData.role === 'coach') {
    // First, clear coach_id from any previous team this user was coaching
    const { error: clearError } = await supabase
      .from('teams')
      .update({ coach_id: null })
      .eq('coach_id', userId);
    
    if (clearError) console.warn('Failed to clear previous team coach:', clearError);
    
    // Then, if assigned to a new team, set this user as the coach
    if (profileData.team_id) {
      const { error: teamError } = await supabase
        .from('teams')
        .update({ coach_id: userId })
        .eq('id', profileData.team_id);
      
      if (teamError) console.warn('Failed to update team coach:', teamError);
    }
    
    // Only refresh dashboard data if the user is on dashboard page
    if (window.location.pathname.includes('dashboard.html')) {
      debouncedRefreshDashboardData();
    } else {
      debouncedRefreshTeamData();
    }
  }

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

/**
 * Clear coach assignment from team (used when coach changes teams)
 */
export async function clearTeamCoach(teamId) {
  const { error } = await supabase
    .from('teams')
    .update({ coach_id: null })
    .eq('id', teamId);

  if (error) throw error;
}

/**
 * Refresh teams data - utility function for UI updates
 */
export async function refreshTeamsData() {
  // This function can be called to trigger UI refresh
  // Implementation depends on how the UI handles data updates
  if (typeof window !== 'undefined' && window.loadTeams) {
    window.loadTeams();
  }
}