/**
 * Authentication Module
 * Handles login, registration, and session management
 */

import {
  supabase,
  signUp,
  signIn,
  signOut as supabaseSignOut,
  getCurrentUser,
  getCurrentUserProfile,
  onAuthStateChange
} from './supabaseClient.js';

// Role-based permission map
const PERMISSIONS = {
  // Who can manage players (add/edit/delete)
  manage_players:     ['admin', 'team_manager', 'coach'],
  // Who can view players
  view_players:       ['admin', 'team_manager', 'coach', 'medical_staff', 'game_official', 'player'],
  // Who can manage training & attendance
  manage_training:    ['admin', 'team_manager', 'coach'],
  view_training:      ['admin', 'team_manager', 'coach', 'player'],
  // Who can manage medical records
  manage_medical:     ['admin', 'team_manager', 'medical_staff'],
  view_medical:       ['admin', 'team_manager', 'medical_staff', 'coach'],
  // Who can create/update match results
  manage_results:     ['game_official'],
  view_results:       ['admin', 'team_manager', 'coach', 'game_official', 'player'],
  // Who can manage teams
  manage_teams:       ['admin', 'team_manager'],
  // Who can manage schedules/events
  manage_schedule:    ['admin', 'team_manager', 'coach'],
  view_schedule:      ['admin', 'team_manager', 'coach', 'medical_staff', 'game_official', 'player'],
};

class AuthManager {
  constructor() {
    this.currentUser = null;
    this.currentProfile = null;
  }

  async init() {
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        this.currentUser = session.user;
        this.currentProfile = await getCurrentUserProfile();
      }

      return onAuthStateChange(async (user) => {
        this.currentUser = user;
        if (user) {
          try {
            this.currentProfile = await getCurrentUserProfile();
          } catch (error) {
            console.error('Failed to load profile:', error);
            this.currentProfile = null;
          }
        } else {
          this.currentProfile = null;
        }
        this.notifyListeners();
      });
    } catch (error) {
      console.error('Auth initialization failed:', error);
      throw error;
    }
  }

  async register(email, password, role = 'player', teamId = null) {
    try {
      return await signUp(email, password, { role, team_id: teamId });
    } catch (error) {
      throw new Error(`Registration failed: ${error.message}`);
    }
  }

  async login(email, password) {
    try {
      return await signIn(email, password);
    } catch (error) {
      throw new Error(`Login failed: ${error.message}`);
    }
  }

  async logout() {
    try {
      await supabaseSignOut();
    } catch (error) {
      throw new Error(`Logout failed: ${error.message}`);
    }
  }

  getUser() { return this.currentUser; }
  getProfile() { return this.currentProfile; }
  getRole() { return this.currentProfile?.role || null; }

  /**
   * Check if current user has permission for an action
   */
  can(action) {
    const role = this.getRole();
    if (!role) return false;
    return (PERMISSIONS[action] || []).includes(role);
  }

  hasAnyRole(roles) {
    return roles.includes(this.currentProfile?.role);
  }

  async refreshProfile() {
    if (this.currentUser) {
      try {
        this.currentProfile = await getCurrentUserProfile();
        this.notifyListeners();
        return this.currentProfile;
      } catch (error) {
        console.error('Failed to refresh profile:', error);
        throw error;
      }
    }
    return null;
  }

  subscribe(callback) {
    this.listeners = this.listeners || [];
    this.listeners.push(callback);
    return () => { this.listeners = this.listeners.filter(l => l !== callback); };
  }

  notifyListeners() {
    (this.listeners || []).forEach(cb => cb(this.currentUser, this.currentProfile));
  }
}

export const authManager = new AuthManager();
export { PERMISSIONS };
