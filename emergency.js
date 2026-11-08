/**
 * ============================================================================
 * MEDTRACK: EMERGENCY MANAGEMENT CONTROLLER
 * FILE: js/emergency.js
 * PURPOSE: Declare emergencies, execute auto-rescheduling, audit replacements
 * ============================================================================
 */

document.addEventListener('DOMContentLoaded', () => {
  initEmergencyForm();
  loadEmergencyDashboard();
  RealtimeEmitter.on('emergency_declared', () => loadEmergencyDashboard());
});

async function initEmergencyForm() {
  const branchSelect = document.getElementById('emg-branch');
  const docSelect = document.getElementById('emg-doctor');

  if (!branchSelect || !docSelect) return;

  const branches = await MedTrackDB.getBranches();
  branchSelect.innerHTML = `<option value="">-- Select Affected Branch --</option>` +
    branches.map(b => `<option value="${b.id}">${b.name} (${b.code})</option>`).join('');

  branchSelect.addEventListener('change', async () => {
    const branchId = branchSelect.value;
    if (!branchId) {
      docSelect.innerHTML = `<option value="">-- All Doctors in Branch --</option>`;
      return;
    }
    const docs = await MedTrackDB.getDoctors(branchId);
    docSelect.innerHTML = `<option value="">-- All Doctors in Branch --</option>` +
      docs.map(d => `<option value="${d.id}">${d.name} (${d.specialization})</option>`).join('');
  });
}

async function handleEmergencyFormSubmit(event) {
  event.preventDefault();

  const branchId = document.getElementById('emg-branch').value;
  const doctorId = document.getElementById('emg-doctor').value || null;
  const startDate = document.getElementById('emg-start-date').value;
  const endDate = document.getElementById('emg-end-date').value;
  const startTime = document.getElementById('emg-start-time').value || '09:00:00';
  const endTime = document.getElementById('emg-end-time').value || '17:00:00';
  const reason = document.getElementById('emg-reason').value;

  if (!branchId || !startDate || !endDate || !reason) {
    alert("Please complete all mandatory emergency fields.");
    return;
  }

  const confirmMsg = `EMERGENCY CONFIRMATION:\n\nAre you sure you want to declare an emergency for this clinic period?\n\nReason: "${reason}"\n\nThis will atomically:\n1. Cancel affected confirmed appointments.\n2. Discover earliest available replacement slots.\n3. Create linked replacement appointments.\n4. Send urgent In-App reschedule notifications to patients.`;

  if (!confirm(confirmMsg)) return;

  const result = await MedTrackDB.reportHospitalEmergency({
    branch_id: branchId,
    doctor_id: doctorId,
    start_date: startDate,
    end_date: endDate,
    start_time: startTime,
    end_time: endTime,
    reason: reason
  });

  if (result.success) {
    alert(`EMERGENCY PROCESSED SUCCESSFULLY!\n\nIncident ID: ${result.event_code}\n\n• Total Affected Appointments: ${result.affected_appointments}\n• Successfully Auto-Rescheduled: ${result.rescheduled_appointments}\n• Awaiting Manual Resolution: ${result.pending_manual_rescheduling}\n• Patient In-App Alerts Dispatched: ${result.rescheduled_appointments}\n\nCheck the notification bell and affected appointments table below.`);
    document.getElementById('emergency-form')?.reset();
    closeModal('emergency-modal');
    loadEmergencyDashboard();
  } else {
    alert(`Emergency processing failed: ${result.message}`);
  }
}

async function loadEmergencyDashboard() {
  const branchFilter = MedTrackAuth.getBranchFilter();
  const allAppts = await MedTrackDB.getAppointments(branchFilter ? { branch_id: branchFilter } : {});

  const affectedAppts = allAppts.filter(a => 
    a.status === 'Cancelled - Emergency' || 
    a.status === 'Awaiting Manual Rescheduling' ||
    a.original_appointment_id
  );

  const container = document.getElementById('emergency-affected-tbody');
  if (!container) return;

  if (affectedAppts.length === 0) {
    container.innerHTML = `<tr><td colspan="7" class="text-muted" style="text-align: center; padding: 24px;">No active emergency cancellations or rescheduled appointments.</td></tr>`;
    return;
  }

  container.innerHTML = affectedAppts.map(a => {
    const isReplacement = !!a.original_appointment_id;
    return `
      <tr>
        <td><strong>${a.number}</strong></td>
        <td>${a.patient_name}</td>
        <td>${a.doctor_name}</td>
        <td>${a.branch_name}</td>
        <td>${a.date} at ${a.time ? a.time.substring(0, 5) : ''}</td>
        <td>
          <span class="badge ${isReplacement ? 'badge-success' : a.status === 'Cancelled - Emergency' ? 'badge-danger' : 'badge-warning'}">
            ${isReplacement ? 'Replacement Created' : a.status}
          </span>
        </td>
        <td><small class="text-muted">${a.emergency_reason || a.reschedule_reason || 'N/A'}</small></td>
      </tr>
    `;
  }).join('');

  // Update summary metrics
  const totalAffected = allAppts.filter(a => a.status === 'Cancelled - Emergency').length;
  const totalRescheduled = allAppts.filter(a => !!a.original_appointment_id).length;
  const totalPending = allAppts.filter(a => a.status === 'Awaiting Manual Rescheduling').length;

  const elAffected = document.getElementById('metric-emg-affected');
  const elRescheduled = document.getElementById('metric-emg-rescheduled');
  const elPending = document.getElementById('metric-emg-pending');

  if (elAffected) elAffected.textContent = totalAffected;
  if (elRescheduled) elRescheduled.textContent = totalRescheduled;
  if (elPending) elPending.textContent = totalPending;
}
