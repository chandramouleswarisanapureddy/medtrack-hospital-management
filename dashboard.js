/**
 * ============================================================================
 * MEDTRACK: DASHBOARD CONTROLLER
 * FILE: js/dashboard.js
 * PURPOSE: Role-aware KPI metrics calculation, recent queue & branch widgets
 * ============================================================================
 */

document.addEventListener('DOMContentLoaded', () => {
  loadDashboardData();
  RealtimeEmitter.on('appointment_created', () => loadDashboardData());
  RealtimeEmitter.on('emergency_declared', () => loadDashboardData());
  RealtimeEmitter.on('inventory_updated', () => loadDashboardData());
});

async function loadDashboardData() {
  const user = MedTrackAuth.getCurrentUser();
  const branchFilter = MedTrackAuth.getBranchFilter();

  const [branches, doctors, patients, appointments, inventory] = await Promise.all([
    MedTrackDB.getBranches(),
    MedTrackDB.getDoctors(branchFilter),
    MedTrackDB.getPatients(branchFilter),
    MedTrackDB.getAppointments(branchFilter ? { branch_id: branchFilter } : {}),
    MedTrackDB.getInventory(branchFilter)
  ]);

  renderKpiCards(user, { branches, doctors, patients, appointments, inventory });
  renderRecentAppointments(appointments);
  renderBranchOverview(branches, appointments);
}

function renderKpiCards(user, data) {
  const container = document.getElementById('dashboard-kpis');
  if (!container) return;

  const totalAppts = data.appointments.length;
  const confirmedAppts = data.appointments.filter(a => a.status === 'Confirmed').length;
  const emergencyAppts = data.appointments.filter(a => a.status === 'Cancelled - Emergency' || a.status === 'Awaiting Manual Rescheduling').length;
  const lowStockCount = data.inventory.filter(i => i.quantity <= i.reorder).length;

  container.innerHTML = `
    <div class="kpi-card">
      <div class="kpi-info">
        <span>Total Appointments</span>
        <h3>${totalAppts}</h3>
        <p class="kpi-subtext">${confirmedAppts} Active Confirmed</p>
      </div>
      <div class="kpi-icon blue">
        <svg width="28" height="28" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
      </div>
    </div>

    <div class="kpi-card">
      <div class="kpi-info">
        <span>Active Doctors</span>
        <h3>${data.doctors.length}</h3>
        <p class="kpi-subtext">Across ${user.role === 'super_admin' ? '3 Branches' : 'This Branch'}</p>
      </div>
      <div class="kpi-icon teal">
        <svg width="28" height="28" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"/></svg>
      </div>
    </div>

    <div class="kpi-card">
      <div class="kpi-info">
        <span>Emergency Events</span>
        <h3 class="${emergencyAppts > 0 ? 'text-danger' : ''}">${emergencyAppts}</h3>
        <p class="kpi-subtext" style="${emergencyAppts > 0 ? 'color: var(--danger);' : ''}">${emergencyAppts > 0 ? 'Auto-Rescheduled / Action' : 'All Clear'}</p>
      </div>
      <div class="kpi-icon red">
        <svg width="28" height="28" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/></svg>
      </div>
    </div>

    <div class="kpi-card">
      <div class="kpi-info">
        <span>Low Stock Alerts</span>
        <h3 class="${lowStockCount > 0 ? 'text-warning' : ''}">${lowStockCount}</h3>
        <p class="kpi-subtext" style="${lowStockCount > 0 ? 'color: var(--warning);' : ''}">${lowStockCount > 0 ? 'Reorder Required' : 'Adequate Stock'}</p>
      </div>
      <div class="kpi-icon amber">
        <svg width="28" height="28" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"/></svg>
      </div>
    </div>
  `;
}

function renderRecentAppointments(appointments) {
  const tbody = document.getElementById('recent-appointments-tbody');
  if (!tbody) return;

  if (appointments.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" class="text-muted" style="text-align: center; padding: 24px;">No appointments on record.</td></tr>`;
    return;
  }

  tbody.innerHTML = appointments.slice(-6).reverse().map(a => {
    let badgeClass = 'badge-primary';
    if (a.status === 'Confirmed') badgeClass = 'badge-success';
    if (a.status === 'Cancelled - Emergency') badgeClass = 'badge-danger';
    if (a.status === 'Awaiting Manual Rescheduling') badgeClass = 'badge-warning';

    return `
      <tr>
        <td><strong>${a.number}</strong></td>
        <td>${a.patient_name}</td>
        <td>${a.doctor_name}</td>
        <td>${a.branch_name}</td>
        <td>${a.date} <span class="text-muted">${a.time ? a.time.substring(0, 5) : ''}</span></td>
        <td><span class="badge ${badgeClass}">${a.status}</span></td>
        <td><span class="badge ${a.risk_level === 'High' ? 'badge-danger' : a.risk_level === 'Medium' ? 'badge-warning' : 'badge-neutral'}">Risk: ${a.risk_level || 'Low'}</span></td>
      </tr>
    `;
  }).join('');
}

function renderBranchOverview(branches, appointments) {
  const container = document.getElementById('branch-overview-grid');
  if (!container) return;

  container.innerHTML = branches.map(b => {
    const branchAppts = appointments.filter(a => a.branch_id === b.id);
    const confirmedCount = branchAppts.filter(a => a.status === 'Confirmed').length;
    const emergencyCount = branchAppts.filter(a => a.status === 'Cancelled - Emergency').length;

    return `
      <div class="card">
        <div class="card-header">
          <h4>${b.name}</h4>
          <span class="badge badge-primary">${b.code}</span>
        </div>
        <p class="text-muted" style="font-size: 0.85rem; margin-bottom: 14px;">${b.address}, ${b.city}</p>
        <div style="display: flex; justify-content: space-between; font-size: 0.85rem; padding: 8px 0; border-top: 1px solid var(--border-color);">
          <span>Active Bookings:</span>
          <strong>${confirmedCount}</strong>
        </div>
        <div style="display: flex; justify-content: space-between; font-size: 0.85rem; padding: 8px 0; border-top: 1px solid var(--border-color);">
          <span>Emergency Events:</span>
          <strong class="${emergencyCount > 0 ? 'text-danger' : ''}">${emergencyCount}</strong>
        </div>
        <div style="margin-top: 16px;">
          <a href="appointments.html?branch=${b.id}" class="btn btn-sm btn-outline" style="width: 100%;">View Branch Queue</a>
        </div>
      </div>
    `;
  }).join('');
}
