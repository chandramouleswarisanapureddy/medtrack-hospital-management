/**
 * ============================================================================
 * MEDTRACK: APPOINTMENT MANAGEMENT CONTROLLER
 * FILE: js/appointments.js
 * PURPOSE: Booking wizard, schedule validation, cancellation & ML risk estimator
 * ============================================================================
 */

document.addEventListener('DOMContentLoaded', () => {
  initAppointmentBookingForm();
  loadAppointmentsTable();
  RealtimeEmitter.on('appointment_created', () => loadAppointmentsTable());
  RealtimeEmitter.on('emergency_declared', () => loadAppointmentsTable());
});

async function initAppointmentBookingForm() {
  const branchSelect = document.getElementById('book-branch');
  const deptSelect = document.getElementById('book-dept');
  const doctorSelect = document.getElementById('book-doctor');

  if (!branchSelect || !deptSelect || !doctorSelect) return;

  const [branches, depts] = await Promise.all([
    MedTrackDB.getBranches(),
    MedTrackDB.getDepartments()
  ]);

  branchSelect.innerHTML = `<option value="">-- Choose Branch --</option>` + 
    branches.map(b => `<option value="${b.id}">${b.name} (${b.code})</option>`).join('');

  deptSelect.innerHTML = `<option value="">-- Choose Department --</option>` +
    depts.map(d => `<option value="${d.id}">${d.name}</option>`).join('');

  // Dynamic filter for doctors based on selected branch and department
  const updateDoctorDropdown = async () => {
    const selectedBranch = branchSelect.value;
    const selectedDept = deptSelect.value;

    if (!selectedBranch || !selectedDept) {
      doctorSelect.innerHTML = `<option value="">-- Select Branch & Dept First --</option>`;
      doctorSelect.disabled = true;
      return;
    }

    const doctors = await MedTrackDB.getDoctors(selectedBranch);
    const filteredDocs = doctors.filter(d => d.department_id === selectedDept);

    if (filteredDocs.length === 0) {
      doctorSelect.innerHTML = `<option value="">No doctors available in this department</option>`;
      doctorSelect.disabled = true;
    } else {
      doctorSelect.innerHTML = `<option value="">-- Select Doctor --</option>` +
        filteredDocs.map(d => `<option value="${d.id}">${d.name} (${d.specialization}) - ₹${d.fee}</option>`).join('');
      doctorSelect.disabled = false;
    }
  };

  branchSelect.addEventListener('change', updateDoctorDropdown);
  deptSelect.addEventListener('change', updateDoctorDropdown);
}

async function handleBookAppointmentSubmit(event) {
  event.preventDefault();

  const branchId = document.getElementById('book-branch').value;
  const deptId = document.getElementById('book-dept').value;
  const doctorId = document.getElementById('book-doctor').value;
  const patientName = document.getElementById('book-patient-name').value;
  const patientPhone = document.getElementById('book-patient-phone').value;
  const date = document.getElementById('book-date').value;
  const time = document.getElementById('book-time').value;
  const reason = document.getElementById('book-reason').value;
  const leadDays = parseInt(document.getElementById('book-lead-days')?.value || '5', 10);
  const smsActive = document.getElementById('book-sms-toggle')?.checked ?? true;

  if (!branchId || !deptId || !doctorId || !date || !time || !patientName) {
    alert("Please fill in all mandatory appointment fields.");
    return;
  }

  // Calculate AI No-Show Risk (mirrors Scikit-learn formula)
  let calculatedRisk = 0.12 + (leadDays / 60.0) * 0.35 - (smsActive ? 0.08 : 0);
  calculatedRisk = Math.min(Math.max(calculatedRisk, 0.05), 0.85);
  const riskLevel = calculatedRisk >= 0.55 ? 'High' : calculatedRisk >= 0.30 ? 'Medium' : 'Low';

  const user = MedTrackAuth.getCurrentUser();

  const result = await MedTrackDB.bookAppointment({
    branch_id: branchId,
    department_id: deptId,
    doctor_id: doctorId,
    patient_name: patientName,
    patient_phone: patientPhone,
    patient_id: user.role === 'patient' ? "c0000000-0000-0000-0000-000000000001" : "c0000000-0000-0000-0000-000000000002",
    date: date,
    time: time,
    reason: reason,
    booked_by_user_id: user.id,
    risk_score: calculatedRisk,
    risk_level: riskLevel
  });

  if (result.success) {
    alert(`Appointment Confirmed!\n\nBooking ID: ${result.appointment.number}\nDoctor: ${result.appointment.doctor_name}\nDate: ${result.appointment.date} at ${result.appointment.time}\nToken Number: #${result.appointment.token}\nAI No-Show Risk: ${riskLevel} (${(calculatedRisk*100).toFixed(1)}%)`);
    document.getElementById('booking-form')?.reset();
    closeModal('booking-modal');
    loadAppointmentsTable();
  } else {
    alert(`Booking Error: ${result.message}`);
  }
}

async function loadAppointmentsTable() {
  const tbody = document.getElementById('appointments-table-body');
  if (!tbody) return;

  const branchFilter = MedTrackAuth.getBranchFilter();
  const appointments = await MedTrackDB.getAppointments(branchFilter ? { branch_id: branchFilter } : {});

  if (appointments.length === 0) {
    tbody.innerHTML = `<tr><td colspan="8" class="text-muted" style="text-align: center; padding: 24px;">No appointments found.</td></tr>`;
    return;
  }

  tbody.innerHTML = appointments.map(a => {
    let badgeClass = 'badge-primary';
    if (a.status === 'Confirmed') badgeClass = 'badge-success';
    if (a.status === 'Cancelled - Emergency') badgeClass = 'badge-danger';
    if (a.status === 'Awaiting Manual Rescheduling') badgeClass = 'badge-warning';

    const riskBadge = a.risk_level === 'High' ? 'badge-danger' : a.risk_level === 'Medium' ? 'badge-warning' : 'badge-neutral';

    return `
      <tr>
        <td><strong>${a.number}</strong></td>
        <td>${a.patient_name}</td>
        <td>${a.doctor_name}</td>
        <td>${a.dept_name || 'General'}</td>
        <td>${a.branch_name}</td>
        <td>${a.date} <span class="text-muted">${a.time ? a.time.substring(0, 5) : ''}</span></td>
        <td><span class="badge ${badgeClass}">${a.status}</span></td>
        <td><span class="badge ${riskBadge}">${a.risk_level || 'Low'} (${((a.risk_score || 0.15)*100).toFixed(0)}%)</span></td>
      </tr>
    `;
  }).join('');
}

// Modal helper
function openModal(id) {
  const modal = document.getElementById(id);
  if (modal) modal.classList.add('active');
}

function closeModal(id) {
  const modal = document.getElementById(id);
  if (modal) modal.classList.remove('active');
}
