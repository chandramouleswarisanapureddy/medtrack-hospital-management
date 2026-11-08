/**
 * ============================================================================
 * MEDTRACK: NAVIGATION & GLOBAL SHELL
 * FILE: js/navigation.js
 * PURPOSE: Render unified sidebar, topbar, notification badge & role dropdown
 * ============================================================================
 */

document.addEventListener('DOMContentLoaded', () => {
  renderNavigation();
  initNotificationBell();
});

function renderNavigation() {
  const currentUser = MedTrackAuth.getCurrentUser();
  const currentPath = window.location.pathname.split('/').pop() || 'index.html';

  // 1. Render Sidebar if #sidebar-container exists
  const sidebarContainer = document.getElementById('sidebar-container');
  if (sidebarContainer) {
    sidebarContainer.innerHTML = `
      <aside class="sidebar" id="app-sidebar">
        <div class="sidebar-brand">
          <div class="brand-icon">M</div>
          <div class="brand-text">
            <h2>MedTrack</h2>
            <span>Hospital Network</span>
          </div>
        </div>

        <nav class="sidebar-nav">
          <div class="nav-section-title">Public Portal</div>
          <a href="index.html" class="nav-item ${currentPath === 'index.html' ? 'active' : ''}">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
            Hospital Home
          </a>

          <div class="nav-section-title">Clinical Operations</div>
          <a href="dashboard.html" class="nav-item ${currentPath === 'dashboard.html' ? 'active' : ''}">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"/></svg>
            Dashboard
          </a>

          <a href="appointments.html" class="nav-item ${currentPath === 'appointments.html' ? 'active' : ''}">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
            Appointments
          </a>

          <a href="emergency.html" class="nav-item ${currentPath === 'emergency.html' ? 'active' : ''}" style="color: #f87171;">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
            Emergency Center
          </a>

          <a href="patients.html" class="nav-item ${currentPath === 'patients.html' ? 'active' : ''}">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
            Patients
          </a>

          <a href="doctors.html" class="nav-item ${currentPath === 'doctors.html' ? 'active' : ''}">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
            Doctors & Staff
          </a>

          <a href="pharmacy.html" class="nav-item ${currentPath === 'pharmacy.html' ? 'active' : ''}">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"/></svg>
            Pharmacy & Stock
          </a>

          <div class="nav-section-title">Analytics & Intelligence</div>
          <a href="reports.html" class="nav-item ${currentPath === 'reports.html' ? 'active' : ''}">
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>
            Reports & ML Risk
          </a>
        </nav>

        <div class="sidebar-footer">
          <p>MedTrack v2.4 (Academic Edition)</p>
          <p>Three-Branch Architecture</p>
        </div>
      </aside>
    `;
  }

  // 2. Render Topbar if #topbar-container exists
  const topbarContainer = document.getElementById('topbar-container');
  if (topbarContainer) {
    topbarContainer.innerHTML = `
      <header class="topbar">
        <div class="topbar-left">
          <button class="mobile-nav-toggle" id="mobile-toggle" onclick="toggleMobileSidebar()">
            <svg width="24" height="24" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
          </button>
          <div class="branch-indicator">
            <span class="status-dot"></span>
            <span class="branch-label">Branch:</span>
            <strong id="topbar-branch-name">${currentUser.branch_name || 'All Branches'}</strong>
          </div>
        </div>

        <div class="topbar-right">
          <!-- Notification Bell -->
          <button class="notification-bell-btn" id="bell-btn" onclick="toggleNotificationDrawer()" title="View In-App Notifications">
            <svg width="22" height="22" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
            <span class="bell-badge" id="unread-count-badge" style="display: none;">0</span>
          </button>

          <!-- Interactive Academic Role Switcher -->
          <div class="user-profile-menu">
            <div class="user-avatar">${currentUser.name.charAt(0)}</div>
            <div class="user-info">
              <div class="user-name">${currentUser.name}</div>
              <div class="user-role-label">${currentUser.role.replace('_', ' ').toUpperCase()}</div>
            </div>
            <select class="form-select form-select-sm" style="width: auto; padding: 4px 8px; font-size: 0.75rem;" onchange="MedTrackAuth.switchRole(this.value)">
              <option value="SUPER_ADMIN" ${currentUser.role === 'super_admin' ? 'selected' : ''}>Super Admin (All Branches)</option>
              <option value="BRANCH_HEAD_A" ${currentUser.role === 'branch_head' ? 'selected' : ''}>Branch Head (Branch A)</option>
              <option value="DOCTOR_SHARMA" ${currentUser.role === 'doctor' ? 'selected' : ''}>Doctor (Dr. Sharma)</option>
              <option value="RECEPTIONIST_A" ${currentUser.role === 'receptionist' ? 'selected' : ''}>Receptionist (Branch A)</option>
              <option value="PATIENT_RAHUL" ${currentUser.role === 'patient' ? 'selected' : ''}>Patient (Rahul Verma)</option>
            </select>
          </div>
        </div>
      </header>
    `;
  }
}

function toggleMobileSidebar() {
  const sidebar = document.getElementById('app-sidebar');
  if (sidebar) sidebar.classList.toggle('mobile-open');
}

function initNotificationBell() {
  updateNotificationBadge();
  RealtimeEmitter.on('notification_received', () => updateNotificationBadge());
  RealtimeEmitter.on('notifications_changed', () => updateNotificationBadge());
}

async function updateNotificationBadge() {
  const user = MedTrackAuth.getCurrentUser();
  const notifs = await MedTrackDB.getNotifications(user.id);
  const unreadCount = notifs.filter(n => !n.is_read).length;
  
  const badge = document.getElementById('unread-count-badge');
  if (badge) {
    if (unreadCount > 0) {
      badge.textContent = unreadCount;
      badge.style.display = 'flex';
    } else {
      badge.style.display = 'none';
    }
  }
}
