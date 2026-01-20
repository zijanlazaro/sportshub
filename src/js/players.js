/**
 * Player Management Module
 * CRUD operations for player profiles and statistics
 */

import { supabase } from './supabaseClient.js';

/**
 * Get all players for a team
 */
export async function getTeamPlayers(teamId) {
  const { data, error } = await supabase
    .from('players')
    .select(`
      id,
      first_name,
      last_name,
      age,
      position,
      jersey_number,
      height_cm,
      weight_kg,
      user_id,
      created_at,
      player_stats(
        games_played,
        points_scored,
        assists,
        avg_performance_rating
      )
    `)
    .eq('team_id', teamId)
    .order('jersey_number', { ascending: true });

  if (error) throw error;
  return data;
}

/**
 * Get player profile with full details
 */
export async function getPlayerProfile(playerId) {
  const { data, error } = await supabase
    .from('players')
    .select(`
      *,
      player_stats(*),
      medical_records(
        id,
        injury_type,
        injury_date,
        recovery_status,
        clearance_to_play,
        created_at
      )
    `)
    .eq('id', playerId)
    .single();

  if (error) throw error;
  return data;
}

/**
 * Create new player
 */
export async function createPlayer(teamId, playerData) {
  const { data, error } = await supabase
    .from('players')
    .insert({
      team_id: teamId,
      first_name: playerData.first_name,
      last_name: playerData.last_name,
      age: playerData.age,
      position: playerData.position,
      jersey_number: playerData.jersey_number,
      height_cm: playerData.height_cm || null,
      weight_kg: playerData.weight_kg || null,
      user_id: playerData.user_id || null
    })
    .select()
    .single();

  if (error) throw error;

  // Initialize player stats
  await supabase.from('player_stats').insert({
    player_id: data.id
  });

  return data;
}

/**
 * Update player profile
 */
export async function updatePlayer(playerId, updateData) {
  const { data, error } = await supabase
    .from('players')
    .update(updateData)
    .eq('id', playerId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Delete player
 */
export async function deletePlayer(playerId) {
  const { error } = await supabase
    .from('players')
    .delete()
    .eq('id', playerId);

  if (error) throw error;
}

/**
 * Get player statistics
 */
export async function getPlayerStats(playerId) {
  const { data, error } = await supabase
    .from('player_stats')
    .select('*')
    .eq('player_id', playerId)
    .single();

  if (error) throw error;
  return data;
}

/**
 * Update player statistics
 */
export async function updatePlayerStats(playerId, statsData) {
  const { data, error } = await supabase
    .from('player_stats')
    .update(statsData)
    .eq('player_id', playerId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Get team's performance summary
 */
export async function getTeamPerformanceSummary(teamId) {
  const { data, error } = await supabase
    .from('player_performance_summary')
    .select('*')
    .in('id', async () => {
      const { data: playerIds } = await supabase
        .from('players')
        .select('id')
        .eq('team_id', teamId);
      return playerIds?.map(p => p.id) || [];
    });

  if (error) throw error;
  return data;
}

/**
 * Search players by name or jersey number
 */
export async function searchPlayers(teamId, query) {
  const { data, error } = await supabase
    .from('players')
    .select('*')
    .eq('team_id', teamId)
    .or(`first_name.ilike.%${query}%,last_name.ilike.%${query}%,jersey_number.eq.${parseInt(query) || -1}`);

  if (error) throw error;
  return data;
}
