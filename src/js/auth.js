/**
 * Authentication Module
 * Handles login, registration, and session management
 */

import {
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
   * Initialize auth state listener
   */
  init() {
    return onAuthStateChange(async (user) => {
      this.currentUser = user;
      if (user) {
        this.currentProfile = await getCurrentUserProfile();
      } else {
        this.currentProfile = null;
      }
      this.notifyListeners();
    });
  }

  /**
   * Register new user
   */
  async register(email, password, fullName, role = 'player', teamId = null) {
    try {
      const result = await signUp(email, password, {
        full_name: fullName,
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
   * Check if user has specific role
   */
  hasRole(role) {
    return this.currentProfile?.role === role;
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
