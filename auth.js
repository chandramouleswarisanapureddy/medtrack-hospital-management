/**
 * ============================================================================
 * MEDTRACK: AUTHENTICATION & ROLE MANAGEMENT
 * FILE: js/auth.js
 * PURPOSE: Manage current active role, session state, and inline auth modal
 * ============================================================================
 */

const MedTrackAuth = {
  // Retrieve currently active user profile from sessionStorage or default to Super Admin
  getCurrentUser() {
    const saved = sessionStorage.getItem('medtrack_user');
    if (saved) {
      try { return JSON.parse(saved); } catch (e) {}
    }
    return MEDTRACK_CONFIG.ROLES.SUPER_ADMIN;
  },

  setCurrentUser(userObj) {
    sessionStorage.setItem('medtrack_user', JSON.stringify(userObj));
    RealtimeEmitter.emit('user_role_changed', userObj);
  },

  switchRole(roleKey) {
    if (MEDTRACK_CONFIG.ROLES[roleKey]) {
      this.setCurrentUser(MEDTRACK_CONFIG.ROLES[roleKey]);
      window.location.reload();
    }
  },

  isSuperAdmin() {
    return this.getCurrentUser().role === 'super_admin';
  },

  isBranchHead() {
    return this.getCurrentUser().role === 'branch_head';
  },

  isDoctor() {
    return this.getCurrentUser().role === 'doctor';
  },

  isReceptionist() {
    return this.getCurrentUser().role === 'receptionist';
  },

  isPatient() {
    return this.getCurrentUser().role === 'patient';
  },

  getBranchFilter() {
    const user = this.getCurrentUser();
    // Super Admin sees all branches; others restricted to their branch_id
    if (user.role === 'super_admin') return null;
    return user.branch_id;
  },

  signOut() {
    sessionStorage.removeItem('medtrack_user');
    window.location.href = 'index.html';
  }
};
