/**
 * Medical Records Module
 * Injury history, medical notes, and clearance management
 */

import { supabase } from './supabaseClient.js';

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
 * Create new medical record
 */
export async function createMedicalRecord(playerId, recordData, userId) {
  const { data, error } = await supabase
    .from('medical_records')
    .insert({
      player_id: playerId,
      recorded_by: userId,
      injury_type: recordData.injury_type,
      injury_date: recordData.injury_date,
      description: recordData.description,
      recovery_status: recordData.recovery_status || 'recovering',
      clearance_to_play: recordData.clearance_to_play || false
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
 * Delete medical record
 */
export async function deleteMedicalRecord(recordId) {
  const { error } = await supabase
    .from('medical_records')
    .delete()
    .eq('id', recordId);

  if (error) throw error;
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
    .select('injury_type, injury_date, recovery_status')
    .eq('player_id', playerId);

  if (error) throw error;

  return {
    total_injuries: records.length,
    active_injuries: records.filter(r => r.recovery_status === 'recovering').length,
    injury_types: [...new Set(records.map(r => r.injury_type))],
    records
  };
}

/**
 * Get team-wide injury report
 */
export async function getTeamInjuryReport(teamId) {
  const { data, error } = await supabase
    .from('medical_records')
    .select(`
      id,
      injury_type,
      recovery_status,
      players(first_name, last_name, jersey_number)
    `)
    .in('player_id', async () => {
      const { data: players } = await supabase
        .from('players')
        .select('id')
        .eq('team_id', teamId);
      return players?.map(p => p.id) || [];
    })
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data;
}
