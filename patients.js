/**
 * ============================================================================
 * MEDTRACK: PATIENTS DIRECTORY CONTROLLER
 * FILE: js/patients.js
 * PURPOSE: Patient search, registration, and medical history drawer
 * ============================================================================
 */

document.addEventListener('DOMContentLoaded', () => {
  loadPatientsTable();
});

async function loadPatientsTable() {
  const tbody = document.getElementById('patients-tbody');
  if (!tbody) return;

  const branchFilter = MedTrackAuth.getBranchFilter();
  const patients = await MedTrackDB.getPatients(branchFilter);

  if (patients.length === 0) {
    tbody.innerHTML = `<tr><td colspan="7" class="text-muted" style="text-align: center; padding: 24px;">No patient records registered.</td></tr>`;
    return;
  }

  tbody.innerHTML = patients.map(p => `
    <tr>
      <td><strong>${p.identifier}</strong></td>
      <td><strong>${p.name}</strong></td>
      <td>${p.gender}, Age ${calculateAge(p.dob)}</td>
      <td>${p.phone}</td>
      <td><span class="badge badge-info">${p.blood_group || 'N/A'}</span></td>
      <td><small class="text-danger">${p.allergies || 'None'}</small></td>
      <td>
        <button class="btn btn-sm btn-outline" onclick="viewPatientHistory('${p.id}')">
          Medical History
        </button>
      </td>
    </tr>
  `).join('');
}

function calculateAge(dobString) {
  if (!dobString) return '30';
  const birth = new Date(dobString);
  const now = new Date();
  return now.getFullYear() - birth.getFullYear();
}

function viewPatientHistory(patientId) {
  const patient = DEMO_STORE.patients.find(p => p.id === patientId);
  if (!patient) return;

  const modalBody = document.getElementById('patient-detail-body');
  if (modalBody) {
    modalBody.innerHTML = `
      <div style="margin-bottom: 20px;">
        <h3>${patient.name} (${patient.identifier})</h3>
        <p class="text-muted">Blood Group: <strong>${patient.blood_group}</strong> | DOB: ${patient.dob} | Phone: ${patient.phone}</p>
      </div>

      <div class="card" style="margin-bottom: 16px; background-color: #f8fafc;">
        <h4 style="margin-bottom: 8px;">Known Allergies</h4>
        <p class="text-danger" style="font-weight: 600;">${patient.allergies || 'None reported'}</p>
      </div>

      <div class="card" style="margin-bottom: 16px; background-color: #f8fafc;">
        <h4 style="margin-bottom: 8px;">Chronic Medical History</h4>
        <p>${patient.history || 'No chronic illness records logged.'}</p>
      </div>

      <div class="card">
        <h4 style="margin-bottom: 8px;">Recent Prescriptions</h4>
        <ul style="padding-left: 20px; font-size: 0.85rem; color: #334155;">
          <li>Telmisartan 40 mg (1 tab daily in morning) - 30 days</li>
          <li>Atorvastatin 20 mg (1 tab daily at bedtime) - 30 days</li>
        </ul>
      </div>
    `;
    openModal('patient-detail-modal');
  }
}

async function handleAddPatientSubmit(event) {
  event.preventDefault();
  const name = document.getElementById('pat-name').value;
  const dob = document.getElementById('pat-dob').value;
  const gender = document.getElementById('pat-gender').value;
  const blood = document.getElementById('pat-blood').value;
  const phone = document.getElementById('pat-phone').value;
  const allergies = document.getElementById('pat-allergies').value || 'None';
  const history = document.getElementById('pat-history').value || 'None';

  const user = MedTrackAuth.getCurrentUser();
  const branchId = user.branch_id || "a0000000-0000-0000-0000-000000000001";
  const newIdentifier = `MED-PAT-${100 + DEMO_STORE.patients.length + 1}`;

  const newPatient = {
    id: 'pat-' + Date.now(),
    identifier: newIdentifier,
    name: name,
    dob: dob,
    gender: gender,
    blood_group: blood,
    phone: phone,
    allergies: allergies,
    history: history,
    branch_id: branchId
  };

  DEMO_STORE.patients.push(newPatient);
  alert(`Patient Registered Successfully!\n\nPatient ID: ${newIdentifier}\nName: ${name}`);
  document.getElementById('new-patient-form')?.reset();
  closeModal('new-patient-modal');
  loadPatientsTable();
}
