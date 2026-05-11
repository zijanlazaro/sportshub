/**
 * Drills Module
 * Position-based drill tracking and performance analytics
 */

import { supabase } from './supabaseClient.js';

// Position-based drill definitions
export const DRILL_CATEGORIES = {
  'Dribbling and Ball Control': {
    positions: ['all'],
    drills: [
      'Slalom Cone Weaving',
      'Fast Dribbling Drill',
      'Dancing Sambas',
      'Weak-Foot Cone Square'
    ]
  },
  'Passing and Receiving': {
    positions: ['Winger', 'Striker', 'Full Back', 'Defender', 'Midfielder', 'Attacking Midfielder'],
    drills: [
      'Rondo (3v3 + 2, 4v2)',
      'Up Back and Through',
      'Double Passing',
      '1-2 and Cross'
    ]
  },
  'Shooting and Finishing': {
    positions: ['Winger', 'Striker', 'Midfielder', 'Attacking Midfielder'],
    drills: [
      '1v0 - 2v2 Finishing',
      '2 Player Crossing Drill',
      'Penalty Area Rondo',
      '1v1 First Touch and Striker Accuracy'
    ]
  },
  'Defending and Tackling': {
    positions: ['Defender', 'Last Man', 'Full Back', 'Right Defender', 'Left Defender', 'Center Back'],
    drills: [
      '1v1 Lose Your Man',
      'Shed and Go',
      'Ball Strip Drill',
      'Interceptor'
    ]
  },
  'Agility and Conditioning': {
    positions: ['all'],
    drills: [
      'Agility Ladder Drill',
      'Sprint/Tack Back',
      'Dribble Relay'
    ]
  },
  'Goalkeeper Drills': {
    positions: ['Goalkeeper'],
    drills: [
      'Footwork and Handling',
      'Goalkeeper Tennis',
      'Distribution Drill'
    ]
  }
};

/**
 * Get available drills for a player's position
 */
export function getAvailableDrills(position) {
  const available = {};
  
  for (const [category, data] of Object.entries(DRILL_CATEGORIES)) {
    if (data.positions.includes('all') || data.positions.includes(position)) {
      available[category] = data.drills;
    }
  }
  
  return available;
}

/**
 * Get all players with drill performance data
 */
export async function getPlayersDrillProgress(teamId) {
  const { data, error } = await supabase
    .from('player_drill_dashboard')
    .select('*')
    .in('id', async () => {
      const { data: players } = await supabase
        .from('players')
        .select('id')
        .eq('team_id', teamId);
      return players?.map(p => p.id) || [];
    });

  if (error) throw error;
  return data || [];
}

/**
 * Get player drill progress details
 */
export async function getPlayerDrillProgress(playerId) {
  const { data, error } = await supabase
    .from('player_drill_dashboard')
    .select('*')
    .eq('id', playerId)
    .single();

  if (error) throw error;
  return data;
}

/**
 * Get player drill history
 */
export async function getPlayerDrillHistory(playerId) {
  const { data, error } = await supabase
    .from('player_drill_records')
    .select(`
      *,
      recorded_by_user:users!recorded_by(full_name)
    `)
    .eq('player_id', playerId)
    .order('training_date', { ascending: false });

  if (error) throw error;
  return data || [];
}

/**
 * Create drill record
 */
export async function createDrillRecord(playerId, drillData, recordedBy) {
  const { data, error } = await supabase
    .from('player_drill_records')
    .insert({
      player_id: playerId,
      recorded_by: recordedBy,
      training_date: drillData.training_date,
      minutes_trained: drillData.minutes_trained,
      player_position: drillData.player_position,
      drills_completed: drillData.drills_completed,
      notes: drillData.notes || null
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Update drill record
 */
export async function updateDrillRecord(recordId, drillData) {
  const { data, error } = await supabase
    .from('player_drill_records')
    .update({
      training_date: drillData.training_date,
      minutes_trained: drillData.minutes_trained,
      player_position: drillData.player_position,
      drills_completed: drillData.drills_completed,
      notes: drillData.notes || null,
      updated_at: new Date().toISOString()
    })
    .eq('id', recordId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Delete drill record
 */
export async function deleteDrillRecord(recordId) {
  const { error } = await supabase
    .from('player_drill_records')
    .delete()
    .eq('id', recordId);

  if (error) throw error;
}

/**
 * Get performance breakdown
 */
export async function getDrillPerformanceBreakdown(playerId) {
  const { data, error } = await supabase
    .from('player_drill_performance')
    .select('*')
    .eq('player_id', playerId)
    .single();

  if (error) {
    // Return default if no score exists yet
    return {
      performance_score: 0,
      drill_completion_rate: 0,
      attendance_rate: 0,
      training_minutes_total: 0,
      position_specific_score: 0,
      performance_level: 'Beginner',
      total_training_days: 0,
      total_drills_completed: 0,
      training_frequency: 0,
      weekly_progress: 0,
      monthly_progress: 0
    };
  }
  
  return data;
}

/**
 * Manually recalculate performance score
 */
export async function recalculateDrillPerformanceScore(playerId) {
  const { data, error } = await supabase
    .rpc('calculate_drill_performance_score', { p_player_id: playerId });

  if (error) throw error;
  return data;
}

/**
 * Get team drill summary
 */
export async function getTeamDrillSummary(teamId) {
  const { data: players } = await supabase
    .from('players')
    .select('id')
    .eq('team_id', teamId);

  if (!players || players.length === 0) {
    return {
      total_players: 0,
      avg_performance_score: 0,
      elite_count: 0,
      competitive_count: 0,
      active_count: 0,
      developing_count: 0,
      beginner_count: 0,
      total_training_minutes: 0,
      total_drills_completed: 0
    };
  }

  const playerIds = players.map(p => p.id);

  const { data: scores } = await supabase
    .from('player_drill_performance')
    .select('*')
    .in('player_id', playerIds);

  const summary = {
    total_players: players.length,
    avg_performance_score: 0,
    elite_count: 0,
    competitive_count: 0,
    active_count: 0,
    developing_count: 0,
    beginner_count: 0,
    total_training_minutes: 0,
    total_drills_completed: 0
  };

  if (scores && scores.length > 0) {
    summary.avg_performance_score = scores.reduce((sum, s) => sum + (s.performance_score || 0), 0) / scores.length;
    summary.total_training_minutes = scores.reduce((sum, s) => sum + (s.training_minutes_total || 0), 0);
    summary.total_drills_completed = scores.reduce((sum, s) => sum + (s.total_drills_completed || 0), 0);
    
    scores.forEach(s => {
      const level = s.performance_level || 'Beginner';
      summary[`${level.toLowerCase()}_count`]++;
    });
  }

  return summary;
}

/**
 * Get performance level style
 */
export function getPerformanceLevelStyle(level) {
  const styles = {
    'Elite': {
      color: 'text-purple-400',
      bg: 'bg-purple-900',
      border: 'border-purple-500',
      icon: 'fa-crown',
      gradient: 'from-purple-600 to-purple-800'
    },
    'Competitive': {
      color: 'text-blue-400',
      bg: 'bg-blue-900',
      border: 'border-blue-500',
      icon: 'fa-trophy',
      gradient: 'from-blue-600 to-blue-800'
    },
    'Active': {
      color: 'text-green-400',
      bg: 'bg-green-900',
      border: 'border-green-500',
      icon: 'fa-running',
      gradient: 'from-green-600 to-green-800'
    },
    'Developing': {
      color: 'text-yellow-400',
      bg: 'bg-yellow-900',
      border: 'border-yellow-500',
      icon: 'fa-chart-line',
      gradient: 'from-yellow-600 to-yellow-800'
    },
    'Beginner': {
      color: 'text-slate-400',
      bg: 'bg-slate-700',
      border: 'border-slate-500',
      icon: 'fa-seedling',
      gradient: 'from-slate-600 to-slate-800'
    }
  };

  return styles[level] || styles['Beginner'];
}

/**
 * Get progress trend indicator
 */
export function getProgressTrendIndicator(progress) {
  if (progress > 10) {
    return { icon: 'fa-arrow-up', color: 'text-green-400', text: `+${progress.toFixed(1)}%` };
  } else if (progress < -10) {
    return { icon: 'fa-arrow-down', color: 'text-red-400', text: `${progress.toFixed(1)}%` };
  } else {
    return { icon: 'fa-minus', color: 'text-slate-400', text: 'Stable' };
  }
}

/**
 * Export drill data to CSV
 */
export function exportDrillDataToCSV(drillRecords) {
  const headers = ['Date', 'Player', 'Position', 'Minutes', 'Drills Completed', 'Notes'];
  const rows = drillRecords.map(record => [
    record.training_date,
    `${record.first_name} ${record.last_name}`,
    record.player_position,
    record.minutes_trained,
    Array.isArray(record.drills_completed) ? record.drills_completed.length : 0,
    record.notes || ''
  ]);

  const csvContent = [
    headers.join(','),
    ...rows.map(row => row.map(cell => `"${cell}"`).join(','))
  ].join('\n');

  const blob = new Blob([csvContent], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `drill_records_${new Date().toISOString().split('T')[0]}.csv`;
  link.click();
  URL.revokeObjectURL(url);
}
