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

class AuthManager {
  constructor() {
    this.currentUser = null;
    this.currentProfile = null;
  }

  /**
   * Initialize auth state listener with better error handling
   */
  async init() {
    try {
      // Get initial session
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        this.currentUser = session.user;
        this.currentProfile = await getCurrentUserProfile();
      }

      // Set up auth state listener
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

  /**
   * Register new user
   */
  async register(email, password, role = 'player', teamId = null) {
    try {
      const result = await signUp(email, password, {
        role,
        team_id: teamId
      });
      return result;
    } catch (error) {
      throw new Error(`Registration failed: ${error.message}`);
    }
  }

  /**
   * Login user
   */
  async login(email, password) {
    try {
      const result = await signIn(email, password);
      return result;
    } catch (error) {
      throw new Error(`Login failed: ${error.message}`);
    }
  }

  /**
   * Logout user
   */
  async logout() {
    try {
      await supabaseSignOut();
    } catch (error) {
      throw new Error(`Logout failed: ${error.message}`);
    }
  }

  /**
   * Get current user
   */
  getUser() {
    return this.currentUser;
  }

  /**
   * Get current user profile
   */
  getProfile() {
    return this.currentProfile;
  }

  /**
   * Refresh current user profile
   */
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

  /**
   * Check if user is in specific role list
   */
  hasAnyRole(roles) {
    return roles.includes(this.currentProfile?.role);
  }

  /**
   * Subscribe to auth changes
   */
  subscribe(callback) {
    this.listeners = this.listeners || [];
    this.listeners.push(callback);
    return () => {
      this.listeners = this.listeners.filter(l => l !== callback);
    };
  }

  /**
   * Notify all listeners of auth changes
   */
  notifyListeners() {
    (this.listeners || []).forEach(cb => cb(this.currentUser, this.currentProfile));
  }
}

export const authManager = new AuthManager();
