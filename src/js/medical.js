/**
 * Medical Records Module - Enhanced
 * Injury history, medical notes, clearance management, and availability tracking
 */

import { supabase } from './supabaseClient.js';
import { updatePlayerAnalytics } from './analytics.js';

/**
 * Get all medical records for a player
 */
export async function getPlayerMedicalRecords(playerId) {
  const { data, error } = await supabase
    .from('medical_records')
    .select(`
      *,
      medical_documents(*)
    `)
    .eq('player_id', playerId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data;
}

/**
 * Get single medical record
 */
export async function getMedicalRecord(recordId) {
  const { data, error } = await supabase
    .from('medical_records')
    .select(`
      *,
      medical_documents(*)
    `)
    .eq('id', recordId)
    .single();

  if (error) throw error;
  return data;
}

/**
 * Create new medical record with enhanced tracking
 */
export async function createMedicalRecord(playerId, recordData, userId) {
  // Verify user is authenticated
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    throw new Error('Authentication required');
  }

  const { data, error } = await supabase
    .from('medical_records')
    .insert({
      player_id: playerId,
      recorded_by: userId,
      injury_type: recordData.injury_type,
      injury_date: recordData.injury_date,
      description: recordData.description,
      severity: recordData.severity || null,
      recovery_status: recordData.recovery_status || 'recovering',
      clearance_to_play: recordData.clearance_to_play || false,
      restrictions: recordData.restrictions || null,
      treatment: recordData.treatment || null,
      expected_return_date: recordData.expected_return_date || null,
      follow_up_required: recordData.follow_up_required || false,
      follow_up_date: recordData.follow_up_date || null,
      blood_pressure: recordData.blood_pressure || null,
      heart_rate: recordData.heart_rate || null,
      temperature: recordData.temperature || null,
      weight: recordData.weight || null
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Update medical record
 */
export async function updateMedicalRecord(recordId, updateData) {
  // Verify user is authenticated
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    throw new Error('Authentication required');
  }

  const { data, error } = await supabase
    .from('medical_records')
    .update({
      ...updateData,
      updated_at: new Date().toISOString()
    })
    .eq('id', recordId)
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Delete medical record with session validation
 */
export async function deleteMedicalRecord(recordId) {
  // Verify user is authenticated
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    throw new Error('Authentication required');
  }

  const { error } = await supabase
    .from('medical_records')
    .delete()
    .eq('id', recordId);

  if (error) throw error;
}

/**
 * Create medical assessment
 */
export async function createMedicalAssessment(playerId, assessmentData, userId) {
  const { data, error } = await supabase
    .from('medical_assessments')
    .insert({
      player_id: playerId,
      assessed_by: userId,
      assessment_date: assessmentData.assessment_date || new Date().toISOString().split('T')[0],
      assessment_type: assessmentData.assessment_type || 'routine',
      overall_fitness: assessmentData.overall_fitness,
      cardiovascular_score: assessmentData.cardiovascular_score,
      strength_score: assessmentData.strength_score,
      flexibility_score: assessmentData.flexibility_score,
      injury_risk_level: assessmentData.injury_risk_level || 'low',
      recommendations: assessmentData.recommendations,
      cleared_for_full_activity: assessmentData.cleared_for_full_activity || false,
      restrictions: assessmentData.restrictions,
      next_assessment_date: assessmentData.next_assessment_date
    })
    .select()
    .single();

  if (error) throw error;

  // Update player analytics with fitness data
  await updatePlayerAnalytics(playerId, {
    fitness_score: assessmentData.overall_fitness,
    availability_status: assessmentData.cleared_for_full_activity ? 'available' : 'restricted',
    next_medical_checkup: assessmentData.next_assessment_date
  });

  return data;
}

/**
 * Get player's latest medical assessment
 */
export async function getLatestMedicalAssessment(playerId) {
  const { data, error } = await supabase
    .from('medical_assessments')
    .select('*')
    .eq('player_id', playerId)
    .order('assessment_date', { ascending: false })
    .limit(1)
    .single();

  if (error && error.code !== 'PGRST116') throw error; // PGRST116 = no rows returned
  return data;
}

/**
 * Upload medical document
 */
export async function uploadMedicalDocument(recordId, file, fileName) {
  const fileExt = fileName.split('.').pop();
  const filePath = `medical-docs/${recordId}/${Date.now()}.${fileExt}`;

  // Upload to storage
  const { error: uploadError } = await supabase.storage
    .from('medical-documents')
    .upload(filePath, file);

  if (uploadError) throw uploadError;

  // Create document record
  const { data, error } = await supabase
    .from('medical_documents')
    .insert({
      medical_record_id: recordId,
      file_path: filePath,
      file_name: fileName,
      file_type: file.type
    })
    .select()
    .single();

  if (error) throw error;
  return data;
}

/**
 * Get medical document download URL
 */
export async function getMedicalDocumentUrl(filePath) {
  const { data } = supabase.storage
    .from('medical-documents')
    .getPublicUrl(filePath);

  return data.publicUrl;
}

/**
 * Delete medical document
 */
export async function deleteMedicalDocument(docId, filePath) {
  // Delete from storage
  const { error: deleteError } = await supabase.storage
    .from('medical-documents')
    .remove([filePath]);

  if (deleteError) throw deleteError;

  // Delete record
  const { error } = await supabase
    .from('medical_documents')
    .delete()
    .eq('id', docId);

  if (error) throw error;
}

/**
 * Get injury statistics for a player
 */
export async function getPlayerInjuryStats(playerId) {
  const { data: records, error } = await supabase
    .from('medical_records')
    .select('injury_type, injury_date, recovery_status, severity')
    .eq('player_id', playerId);

  if (error) throw error;

  return {
    total_injuries: records.length,
    active_injuries: records.filter(r => r.recovery_status === 'recovering').length,
    severe_injuries: records.filter(r => ['severe', 'critical'].includes(r.severity)).length,
    injury_types: [...new Set(records.map(r => r.injury_type))],
    records
  };
}

/**
 * Clear player for activity
 */
export async function clearPlayerForActivity(playerId, userId, clearanceData) {
  // Update latest medical record
  const { data: latestRecord } = await supabase
    .from('medical_records')
    .select('id')
    .eq('player_id', playerId)
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  if (latestRecord) {
    await updateMedicalRecord(latestRecord.id, {
      recovery_status: 'cleared',
      clearance_to_play: true,
      actual_return_date: new Date().toISOString().split('T')[0],
      restrictions: clearanceData.restrictions || null
    });
  }

  // Update player analytics
  await updatePlayerAnalytics(playerId, {
    availability_status: clearanceData.restrictions ? 'restricted' : 'available',
    medical_clearance_date: new Date().toISOString().split('T')[0]
  });

  return { success: true, message: 'Player cleared for activity' };
}

/**
 * Get player's medical clearance status
 */
export async function getPlayerMedicalStatus(playerId) {
  const { data, error } = await supabase
    .from('player_medical_status')
    .select('*')
    .eq('player_id', playerId)
    .single();

  if (error && error.code !== 'PGRST116') throw error;
  return data;
}

/**
 * Get all players with their medical clearance status
 */
export async function getTeamMedicalStatus(teamId) {
  const { data, error } = await supabase
    .from('player_medical_status')
    .select(`
      *,
      players!inner(team_id)
    `)
    .eq('players.team_id', teamId);

  if (error) throw error;
  return data;
}
