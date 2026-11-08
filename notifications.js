/**
 * ============================================================================
 * MEDTRACK: NOTIFICATIONS CONTROLLER
 * FILE: js/notifications.js
 * PURPOSE: Manage slide-out notification drawer, unread status & emergency alerts
 * ============================================================================
 */

function toggleNotificationDrawer() {
  let drawer = document.getElementById('notification-drawer');
  if (!drawer) {
    createNotificationDrawer();
    drawer = document.getElementById('notification-drawer');
  }
  drawer.classList.toggle('open');
  if (drawer.classList.contains('open')) {
    loadNotificationsList();
  }
}

function createNotificationDrawer() {
  const drawer = document.createElement('div');
  drawer.id = 'notification-drawer';
  drawer.className = 'notification-drawer';
  drawer.innerHTML = `
    <div class="drawer-header">
      <h3>Notifications Center</h3>
      <button class="btn-close" onclick="toggleNotificationDrawer()">&times;</button>
    </div>
    <div class="drawer-body" id="drawer-notifs-list">
      <p class="text-muted">Loading notifications...</p>
    </div>
  `;
  document.body.appendChild(drawer);
}

async function loadNotificationsList() {
  const container = document.getElementById('drawer-notifs-list');
  if (!container) return;

  const user = MedTrackAuth.getCurrentUser();
  const notifs = await MedTrackDB.getNotifications(user.id);

  if (notifs.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; padding: 40px 20px;">
        <svg width="48" height="48" fill="none" stroke="#94a3b8" viewBox="0 0 24 24" style="margin: 0 auto 12px;"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/></svg>
        <p class="text-muted">No notifications received yet.</p>
      </div>
    `;
    return;
  }

  container.innerHTML = notifs.map(n => `
    <div class="notif-item ${!n.is_read ? 'unread' : ''} ${n.type === 'EMERGENCY_RESCHEDULE' ? 'emergency' : ''}">
      <div class="notif-header">
        <span class="badge ${n.type === 'EMERGENCY_RESCHEDULE' ? 'badge-danger' : 'badge-primary'}">${n.type.replace('_', ' ')}</span>
        <span>${new Date(n.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
      </div>
      <div class="notif-title">${n.title}</div>
      <div class="notif-body">${n.message}</div>
      ${!n.is_read ? `
        <button class="btn btn-sm btn-outline" style="margin-top: 10px; font-size: 0.75rem;" onclick="handleMarkAsRead('${n.id}')">
          Mark as Read
        </button>
      ` : ''}
    </div>
  `).join('');
}

async function handleMarkAsRead(notifId) {
  await MedTrackDB.markNotificationRead(notifId);
  loadNotificationsList();
  updateNotificationBadge();
}
