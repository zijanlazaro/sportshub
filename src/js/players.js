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
      status,
      attendance_streak,
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
 * Upload player photo to Supabase Storage, returns public URL
 */
export async function uploadPlayerPhoto(file, playerId) {
  const ext = file.name.split('.').pop();
  const path = `players/${playerId}.${ext}`;
  const { error } = await supabase.storage.from('player-photos').upload(path, file, { upsert: true });
  if (error) throw error;
  const { data } = supabase.storage.from('player-photos').getPublicUrl(path);
  return data.publicUrl;
}

/**
 * Get player full progress report: attendance streak, performance score, recommendation
 */
export async function getPlayerProgressReport(playerId) {
  const [{ data: player }, { data: stats }, { data: attendance }] = await Promise.all([
    supabase.from('players').select('*').eq('id', playerId).single(),
    supabase.from('player_stats').select('*').eq('player_id', playerId).single(),
    supabase.from('training_attendance')
      .select('attendance_status, training_sessions(session_date)')
      .eq('player_id', playerId)
      .order('training_sessions(session_date)', { ascending: false })
      .limit(30)
  ]);

  const records = attendance || [];
  const totalSessions = records.length;
  const presentCount = records.filter(r => r.attendance_status === 'present').length;
  const attendanceRate = totalSessions > 0 ? (presentCount / totalSessions) * 100 : 0;

  // Consecutive streak
  let streak = 0;
  for (const r of records) {
    if (r.attendance_status === 'present') streak++;
    else break;
  }

  // Performance score (0-100)
  const gamesPlayed = stats?.games_played || 0;
  const goals = stats?.goals_scored || stats?.points_scored || 0;
  const assists = stats?.assists || 0;
  const rating = stats?.avg_performance_rating || stats?.rating || 0;

  const performanceScore = Math.min(100, Math.round(
    (attendanceRate * 0.4) +
    (Math.min(rating, 10) * 4) +
    (Math.min(goals / Math.max(gamesPlayed, 1), 1) * 10) +
    (Math.min(assists / Math.max(gamesPlayed, 1), 1) * 6)
  ));

  // Recommendation
  let recommendation;
  if (performanceScore >= 75 && attendanceRate >= 80) recommendation = 'Starter';
  else if (performanceScore >= 55 && attendanceRate >= 60) recommendation = 'Bench';
  else if (attendanceRate >= 40) recommendation = 'Monitor';
  else recommendation = 'Needs Improvement';

  return {
    player,
    stats,
    attendanceRate: Math.round(attendanceRate),
    streak,
    totalSessions,
    presentCount,
    performanceScore,
    recommendation
  };
}

/**
 * Check consecutive attendance and auto-promote Tryout -> Official Player
 */
export async function checkAndPromotePlayer(playerId) {
  const { data: records } = await supabase
    .from('training_attendance')
    .select('attendance_status, training_sessions(session_date)')
    .eq('player_id', playerId)
    .order('training_sessions(session_date)', { ascending: false })
    .limit(3);

  if (!records || records.length < 3) return null;

  const allPresent = records.every(r => r.attendance_status === 'present');
  if (!allPresent) return null;

  const { data: player } = await supabase.from('players').select('status').eq('id', playerId).single();
  if (player?.status !== 'Tryout') return null;

  const { data, error } = await supabase
    .from('players')
    .update({ status: 'Official Player', attendance_streak: 3 })
    .eq('id', playerId)
    .select()
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
      age: playerData.age || null,
      position: playerData.position,
      jersey_number: playerData.jersey_number,
      height_cm: playerData.height_cm || null,
      weight_kg: playerData.weight_kg || null,
      date_of_birth: playerData.date_of_birth || null,
      place_of_birth: playerData.place_of_birth || null,
      years_active: playerData.years_active || null,
      recent_tournament: playerData.recent_tournament || null,
      medical_conditions: playerData.medical_conditions || null,
      medication: playerData.medication || null,
      history_of_seizure: playerData.history_of_seizure || null,
      recent_injury: playerData.recent_injury || null,
      surgery_history: playerData.surgery_history || null,
      pain_during_activity: playerData.pain_during_activity || null,
      fit_for_high_intensity: playerData.fit_for_high_intensity || null,
      blood_type: playerData.blood_type || null,
      emergency_contact_name: playerData.emergency_contact_name || null,
      emergency_contact_number: playerData.emergency_contact_number || null,
      emergency_contact_relationship: playerData.emergency_contact_relationship || null,
      user_id: playerData.user_id || null,
      status: 'Tryout',
      attendance_streak: 0
      // photo_url is set separately after upload
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
