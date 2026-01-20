/**
 * Analytics Module
 * Comprehensive analytics, statistics, and player availability tracking
 */

import { supabase } from './supabaseClient.js';

/**
 * Get player availability status based on latest medical records
 */
export async function getPlayerAvailabilityStatus(playerId) {
  const { data, error } = await supabase
    .from('player_availability_status')
    .select('*')
    .eq('id', playerId)
    .single();

  if (error) throw error;
  return data;
}

/**
 * Get team availability overview
 */
export async function getTeamAvailabilityOverview(teamId) {
  const { data, error } = await supabase
    .from('player_availability_status')
    .select('*')
    .in('id', async () => {
      const { data: players } = await supabase
        .from('players')
        .select('id')
        .eq('team_id', teamId);
      return players?.map(p => p.id) || [];
    });

  if (error) throw error;

  const summary = {
    total: data.length,
    available: data.filter(p => p.work_readiness === 'Ready to Play').length,
    injured: data.filter(p => p.work_readiness === 'Not Available').length,
    restricted: data.filter(p => p.work_readiness === 'Limited Availability').length,
    unknown: data.filter(p => p.work_readiness === 'Status Unknown').length
  };

  return { players: data, summary };
}

/**
 * Update player analytics data
 */
export async function updatePlayerAnalytics(playerId, analyticsData) {
  const { data, error } = await supabase
    .from('player_analytics')
    .upsert({
      player_id: playerId,
      date: new Date().toISOString().split('T')[0],
      ...analyticsData,
      updated_at: new Date().toISOString()
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Get team performance dashboard data
 */
export async function getTeamPerformanceDashboard(teamId) {
  const { data, error } = await supabase
    .from('team_performance_dashboard')
    .select('*')
    .eq('team_id', teamId)
    .single();

  if (error) throw error;
  return data;
}

/**
 * Get medical analytics for a team
 */
export async function getMedicalAnalytics(teamId) {
  const { data, error } = await supabase
    .from('medical_analytics')
    .select('*')
    .eq('team_id', teamId)
    .single();

  if (error) throw error;
  return data;
}

/**
 * Get player performance trends over time
 */
export async function getPlayerPerformanceTrends(playerId, days = 30) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);

  const { data, error } = await supabase
    .from('player_analytics')
    .select('*')
    .eq('player_id', playerId)
    .gte('date', startDate.toISOString().split('T')[0])
    .order('date', { ascending: true });

  if (error) throw error;
  return data;
}

/**
 * Get team injury statistics
 */
export async function getTeamInjuryStatistics(teamId) {
  const { data: players } = await supabase
    .from('players')
    .select('id')
    .eq('team_id', teamId);

  if (!players) return null;

  const playerIds = players.map(p => p.id);

  const { data: injuries, error } = await supabase
    .from('medical_records')
    .select(`
      id,
      injury_type,
      injury_date,
      recovery_status,
      severity,
      expected_return_date,
      actual_return_date,
      players(first_name, last_name, jersey_number)
    `)
    .in('player_id', playerIds)
    .order('injury_date', { ascending: false });

  if (error) throw error;

  const stats = {
    total_injuries: injuries.length,
    active_injuries: injuries.filter(i => i.recovery_status === 'recovering').length,
    by_severity: {
      minor: injuries.filter(i => i.severity === 'minor').length,
      moderate: injuries.filter(i => i.severity === 'moderate').length,
      severe: injuries.filter(i => i.severity === 'severe').length,
      critical: injuries.filter(i => i.severity === 'critical').length
    },
    by_type: {},
    recent_injuries: injuries.slice(0, 10)
  };

  // Count by injury type
  injuries.forEach(injury => {
    if (injury.injury_type) {
      stats.by_type[injury.injury_type] = (stats.by_type[injury.injury_type] || 0) + 1;
    }
  });

  return stats;
}

/**
 * Calculate team fitness metrics
 */
export async function calculateTeamFitnessMetrics(teamId) {
  const { data: assessments, error } = await supabase
    .from('medical_assessments')
    .select(`
      overall_fitness,
      cardiovascular_score,
      strength_score,
      flexibility_score,
      injury_risk_level,
      players(team_id)
    `)
    .eq('players.team_id', teamId)
    .order('assessment_date', { ascending: false });

  if (error) throw error;

  if (!assessments || assessments.length === 0) {
    return {
      avg_overall_fitness: 0,
      avg_cardiovascular: 0,
      avg_strength: 0,
      avg_flexibility: 0,
      high_risk_count: 0,
      total_assessed: 0
    };
  }

  const metrics = {
    avg_overall_fitness: assessments.reduce((sum, a) => sum + (a.overall_fitness || 0), 0) / assessments.length,
    avg_cardiovascular: assessments.reduce((sum, a) => sum + (a.cardiovascular_score || 0), 0) / assessments.length,
    avg_strength: assessments.reduce((sum, a) => sum + (a.strength_score || 0), 0) / assessments.length,
    avg_flexibility: assessments.reduce((sum, a) => sum + (a.flexibility_score || 0), 0) / assessments.length,
    high_risk_count: assessments.filter(a => a.injury_risk_level === 'high').length,
    total_assessed: assessments.length
  };

  return metrics;
}

/**
 * Get training attendance analytics
 */
export async function getTrainingAttendanceAnalytics(teamId, days = 30) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);

  const { data, error } = await supabase
    .from('training_attendance_summary')
    .select('*')
    .eq('team_name', async () => {
      const { data: team } = await supabase
        .from('teams')
        .select('name')
        .eq('id', teamId)
        .single();
      return team?.name;
    })
    .gte('session_date', startDate.toISOString().split('T')[0])
    .order('session_date', { ascending: false });

  if (error) throw error;

  const analytics = {
    total_sessions: data.length,
    avg_attendance_rate: data.length > 0 ? 
      data.reduce((sum, s) => sum + (s.attendance_rate || 0), 0) / data.length : 0,
    total_attendees: data.reduce((sum, s) => sum + (s.total_attendees || 0), 0),
    sessions: data
  };

  return analytics;
}

/**
 * Generate comprehensive team report
 */
export async function generateTeamReport(teamId) {
  try {
    const [
      dashboard,
      availability,
      medicalAnalytics,
      injuryStats,
      fitnessMetrics,
      attendanceAnalytics
    ] = await Promise.all([
      getTeamPerformanceDashboard(teamId),
      getTeamAvailabilityOverview(teamId),
      getMedicalAnalytics(teamId),
      getTeamInjuryStatistics(teamId),
      calculateTeamFitnessMetrics(teamId),
      getTrainingAttendanceAnalytics(teamId)
    ]);

    return {
      dashboard,
      availability,
      medical: medicalAnalytics,
      injuries: injuryStats,
      fitness: fitnessMetrics,
      attendance: attendanceAnalytics,
      generated_at: new Date().toISOString()
    };
  } catch (error) {
    throw new Error(`Failed to generate team report: ${error.message}`);
  }
}

/**
 * Update team statistics (should be run daily)
 */
export async function updateTeamStatistics(teamId) {
  const availability = await getTeamAvailabilityOverview(teamId);
  const fitnessMetrics = await calculateTeamFitnessMetrics(teamId);
  const attendanceAnalytics = await getTrainingAttendanceAnalytics(teamId, 7);

  const { data, error } = await supabase
    .from('team_statistics')
    .upsert({
      team_id: teamId,
      date: new Date().toISOString().split('T')[0],
      total_players: availability.summary.total,
      available_players: availability.summary.available,
      injured_players: availability.summary.injured,
      restricted_players: availability.summary.restricted,
      avg_team_fitness: fitnessMetrics.avg_overall_fitness,
      injury_rate: availability.summary.total > 0 ? 
        (availability.summary.injured / availability.summary.total) * 100 : 0,
      training_attendance_avg: attendanceAnalytics.avg_attendance_rate
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Check if player is amenable to work based on medical records
 */
export async function checkPlayerWorkReadiness(playerId) {
  const availability = await getPlayerAvailabilityStatus(playerId);
  
  const workReadiness = {
    status: availability.work_readiness,
    canWork: availability.work_readiness === 'Ready to Play',
    restrictions: availability.restrictions,
    expectedReturn: availability.expected_return_date,
    fitnessScore: availability.fitness_score,
    lastClearance: availability.medical_clearance_date,
    nextCheckup: availability.next_medical_checkup,
    details: {
      medicalClearance: availability.recovery_status === 'cleared',
      availabilityStatus: availability.availability_status,
      hasRestrictions: !!availability.restrictions
    }
  };

  return workReadiness;
}