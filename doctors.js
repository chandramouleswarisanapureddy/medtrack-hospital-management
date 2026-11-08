/**
 * ============================================================================
 * MEDTRACK: DOCTORS & STAFF DIRECTORY
 * FILE: js/doctors.js
 * PURPOSE: Doctor listings, schedule inspections, branch allocations
 * ============================================================================
 */

document.addEventListener('DOMContentLoaded', () => {
  loadDoctorsTable();
});

async function loadDoctorsTable() {
  const tbody = document.getElementById('doctors-tbody');
  if (!tbody) return;

  const branchFilter = MedTrackAuth.getBranchFilter();
  const doctors = await MedTrackDB.getDoctors(branchFilter);

  tbody.innerHTML = doctors.map(d => `
    <tr>
      <td><strong>${d.identifier}</strong></td>
      <td><strong>${d.name}</strong></td>
      <td><span class="badge badge-info">${d.dept_name || d.specialization}</span></td>
      <td>${d.branch_name || 'Assigned Branch'}</td>
      <td>${d.experience} Years</td>
      <td>₹${d.fee}</td>
      <td>
        <span class="badge ${d.available ? 'badge-success' : 'badge-danger'}">
          ${d.available ? 'Available' : 'On Leave'}
        </span>
      </td>
      <td>
        <button class="btn btn-sm btn-outline" onclick="viewSchedule('${d.id}')">View Schedule</button>
      </td>
    </tr>
  `).join('');
}

function viewSchedule(docId) {
  const doctor = DEMO_STORE.doctors.find(d => d.id === docId);
  if (!doctor) return;

  alert(`Doctor Schedule for ${doctor.name} (${doctor.dept_name}):\n\n• Monday to Friday: 09:00 AM - 01:00 PM\n• Slot Duration: 30 minutes\n• Max Patients/Slot: 1\n• Clinic Branch: ${doctor.branch_name}\n• Status: ${doctor.available ? 'Active' : 'Unavailable'}`);
}
