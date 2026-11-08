/**
 * ============================================================================
 * MEDTRACK: ANALYTICAL REPORTS & BI CONTROLLER
 * FILE: js/reports.js
 * PURPOSE: Branch performance metrics, ML benchmarks & analytical CSV exports
 * ============================================================================
 */

document.addEventListener('DOMContentLoaded', () => {
  loadBranchReports();
});

async function loadBranchReports() {
  const [branches, appts, inventory] = await Promise.all([
    MedTrackDB.getBranches(),
    MedTrackDB.getAppointments(),
    MedTrackDB.getInventory()
  ]);

  const tbody = document.getElementById('branch-report-tbody');
  if (!tbody) return;

  tbody.innerHTML = branches.map(b => {
    const bAppts = appts.filter(a => a.branch_id === b.id);
    const completed = bAppts.filter(a => a.status === 'Completed').length;
    const emg = bAppts.filter(a => a.status === 'Cancelled - Emergency').length;
    const noShows = bAppts.filter(a => a.status === 'No-show').length;
    const bInventory = inventory.filter(i => i.branch_id === b.id);
    const lowStock = bInventory.filter(i => i.quantity <= i.reorder).length;
    const revenue = completed * 750; // Average consultation fee

    return `
      <tr>
        <td><strong>${b.name}</strong> (${b.code})</td>
        <td>${bAppts.length}</td>
        <td>${completed}</td>
        <td><span class="${emg > 0 ? 'text-danger font-weight-bold' : ''}">${emg}</span></td>
        <td>${noShows}</td>
        <td><span class="${lowStock > 0 ? 'badge badge-warning' : 'badge badge-success'}">${lowStock} Critical</span></td>
        <td><strong>₹${revenue.toLocaleString('en-IN')}</strong></td>
      </tr>
    `;
  }).join('');
}

function exportOperationalCSV() {
  const rows = [
    ["Branch Code", "Branch Name", "Total Appointments", "Completed", "Emergency Cancelled", "No Shows"],
    ["BRANCH-A", "MedTrack Metro Central", "4", "2", "1", "0"],
    ["BRANCH-B", "MedTrack Tech City", "3", "1", "0", "1"],
    ["BRANCH-C", "MedTrack Green Valley", "3", "2", "0", "0"]
  ];

  let csvContent = "data:text/csv;charset=utf-8," + rows.map(e => e.join(",")).join("\n");
  const encodedUri = encodeURI(csvContent);
  const link = document.createElement("a");
  link.setAttribute("href", encodedUri);
  link.setAttribute("download", `MedTrack_Branch_Report_${new Date().toISOString().split('T')[0]}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
