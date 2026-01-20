/**
 * Training & Events Module
 * Training sessions, attendance, and event scheduling
 */

import { supabase } from './supabaseClient.js';

// ============================================================================
// TRAINING SESSIONS
// ============================================================================

/**
 * Get all training sessions for a team
 */
export async function getTeamTrainingSessions(teamId, limit = 50) {
  const { data, error } = await supabase
    .from('training_sessions')
    .select(`
      *,
      training_attendance(*)
    `)
    .eq('team_id', teamId)
    .order('session_date', { ascending: false })
    .limit(limit);

  if (error) throw error;
  return data;
}

/**
 * Get single training session with attendance
 */
export async function getTrainingSession(sessionId) {
  const { data, error } = await supabase
    .from('training_sessions')
    .select(`
      *,
      training_attendance(
        id,
        player_id,
        attendance_status,
        notes,
        players(first_name, last_name, jersey_number)
      )
    `)
    .eq('id', sessionId)
    .single();

  if (error) throw error;
  return data;
}

/**
 * Create new training session
 */
export async function createTrainingSession(teamId, sessionData, userId) {
  const { data, error } = await supabase
    .from('training_sessions')
    .insert({
      team_id: teamId,
      created_by: userId,
      session_date: sessionData.session_date,
      session_time: sessionData.session_time || null,
      location: sessionData.location || null,
      topic: sessionData.topic || null,
      notes: sessionData.notes || null
    })
    .select()
    .single();

  if (error) throw error;

  // Initialize attendance records for all team players
  const { data: players } = await supabase
    .from('players')
    .select('id')
    .eq('team_id', teamId);

  if (players && players.length > 0) {
    const attendanceRecords = players.map(player => ({
      training_session_id: data.id,
      player_id: player.id,
      attendance_status: 'absent' // Default to absent until marked otherwise
    }));

    await supabase.from('training_attendance').insert(attendanceRecords);
  }

  return data;
}

/**
 * Update training session
 */
export async function updateTrainingSession(sessionId, updateData) {
  const { data, error } = await supabase
    .from('training_sessions')
    .update(updateData)
    .eq('id', sessionId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Delete training session
 */
export async function deleteTrainingSession(sessionId) {
  const { error } = await supabase
    .from('training_sessions')
    .delete()
    .eq('id', sessionId);

  if (error) throw error;
}

// ============================================================================
// TRAINING ATTENDANCE
// ============================================================================

/**
 * Update attendance for a player in a training session
 */
export async function updateAttendance(sessionId, playerId, status, notes = '') {
  const { data, error } = await supabase
    .from('training_attendance')
    .update({
      attendance_status: status,
      notes: notes,
      recorded_at: new Date().toISOString()
    })
    .eq('training_session_id', sessionId)
    .eq('player_id', playerId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Get attendance summary for a training session
 */
export async function getSessionAttendanceSummary(sessionId) {
  const { data, error } = await supabase
    .from('training_attendance_summary')
    .select('*')
    .eq('id', sessionId)
    .single();

  if (error) throw error;
  return data;
}

/**
 * Get player's attendance history
 */
export async function getPlayerAttendanceHistory(playerId, months = 3) {
  const dateThreshold = new Date();
  dateThreshold.setMonth(dateThreshold.getMonth() - months);

  const { data, error } = await supabase
    .from('training_attendance')
    .select(`
      *,
      training_sessions(
        session_date,
        session_time,
        location,
        topic
      )
    `)
    .eq('player_id', playerId)
    .gte('recorded_at', dateThreshold.toISOString())
    .order('recorded_at', { ascending: false });

  if (error) throw error;

  // Calculate stats
  const total = data.length;
  const present = data.filter(d => d.attendance_status === 'present').length;
  const absent = data.filter(d => d.attendance_status === 'absent').length;
  const excused = data.filter(d => d.attendance_status === 'excused').length;

  return {
    history: data,
    stats: {
      total,
      present,
      absent,
      excused,
      attendance_rate: total > 0 ? Math.round((present / total) * 100) : 0
    }
  };
}

/**
 * Bulk update attendance for a session
 */
export async function bulkUpdateAttendance(sessionId, attendanceData) {
  const updates = attendanceData.map(record => ({
    training_session_id: sessionId,
    player_id: record.player_id,
    attendance_status: record.status,
    notes: record.notes || '',
    recorded_at: new Date().toISOString()
  }));

  // Delete old attendance and insert new
  await supabase
    .from('training_attendance')
    .delete()
    .eq('training_session_id', sessionId);

  const { data, error } = await supabase
    .from('training_attendance')
    .insert(updates)
    .select();

  if (error) throw error;
  return data;
}

// ============================================================================
// GAMES
// ============================================================================

/**
 * Get team's game schedule
 */
export async function getTeamGames(teamId, status = null) {
  let query = supabase
    .from('games')
    .select('*')
    .eq('team_id', teamId);

  if (status) {
    query = query.eq('status', status);
  }

  const { data, error } = await query
    .order('game_date', { ascending: true });

  if (error) throw error;
  return data;
}

/**
 * Create new game
 */
export async function createGame(teamId, gameData, userId) {
  const { data, error } = await supabase
    .from('games')
    .insert({
      team_id: teamId,
      opponent_name: gameData.opponent_name,
      game_date: gameData.game_date,
      game_time: gameData.game_time || null,
      location: gameData.location || null,
      status: gameData.status || 'upcoming',
      notes: gameData.notes || null
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Update game
 */
export async function updateGame(gameId, updateData) {
  const { data, error } = await supabase
    .from('games')
    .update(updateData)
    .eq('id', gameId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Delete game
 */
export async function deleteGame(gameId) {
  const { error } = await supabase
    .from('games')
    .delete()
    .eq('id', gameId);

  if (error) throw error;
}

// ============================================================================
// EVENTS
// ============================================================================

/**
 * Get team's calendar events
 */
export async function getTeamEvents(teamId, startDate = null, endDate = null) {
  let query = supabase
    .from('events')
    .select('*')
    .eq('team_id', teamId);

  if (startDate) {
    query = query.gte('event_date', startDate);
  }

  if (endDate) {
    query = query.lte('event_date', endDate);
  }

  const { data, error } = await query
    .order('event_date', { ascending: true });

  if (error) throw error;
  return data;
}

/**
 * Create new event
 */
export async function createEvent(teamId, eventData, userId) {
  const { data, error } = await supabase
    .from('events')
    .insert({
      team_id: teamId,
      created_by: userId,
      event_title: eventData.event_title,
      event_description: eventData.event_description || null,
      event_date: eventData.event_date,
      event_time: eventData.event_time || null,
      event_type: eventData.event_type || 'meeting',
      location: eventData.location || null,
      status: eventData.status || 'upcoming'
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Update event
 */
export async function updateEvent(eventId, updateData) {
  const { data, error } = await supabase
    .from('events')
    .update(updateData)
    .eq('id', eventId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Delete event
 */
export async function deleteEvent(eventId) {
  const { error } = await supabase
    .from('events')
    .delete()
    .eq('id', eventId);

  if (error) throw error;
}
