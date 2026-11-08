/**
 * ============================================================================
 * MEDTRACK: PHARMACY & INVENTORY CONTROLLER
 * FILE: js/pharmacy.js
 * PURPOSE: Stock management, negative stock prevention, sales dispensing
 * ============================================================================
 */

document.addEventListener('DOMContentLoaded', () => {
  loadInventoryTable();
  initDispenseModal();
  RealtimeEmitter.on('inventory_updated', () => loadInventoryTable());
});

async function loadInventoryTable() {
  const tbody = document.getElementById('inventory-tbody');
  if (!tbody) return;

  const branchFilter = MedTrackAuth.getBranchFilter();
  const inventory = await MedTrackDB.getInventory(branchFilter);

  tbody.innerHTML = inventory.map(item => {
    const isLow = item.quantity <= item.reorder;
    const isExpiringSoon = new Date(item.expiry) < new Date('2026-12-31');

    return `
      <tr>
        <td><strong>${item.code}</strong></td>
        <td><strong>${item.name}</strong> <br><small class="text-muted">${item.category}</small></td>
        <td><code>${item.batch}</code></td>
        <td>${item.branch_name}</td>
        <td>
          <strong style="${isLow ? 'color: var(--danger); font-size: 1.1rem;' : ''}">${item.quantity} Units</strong>
          ${isLow ? '<br><small class="badge badge-danger">Reorder Alert (&lt;' + item.reorder + ')</small>' : ''}
        </td>
        <td>₹${item.price.toFixed(2)}</td>
        <td>
          ${item.expiry}
          ${isExpiringSoon ? '<span class="badge badge-warning" style="margin-left: 6px;">Expiring Soon</span>' : ''}
        </td>
        <td>
          <button class="btn btn-sm btn-primary" onclick="openDispenseModal('${item.id}')">Dispense / Sale</button>
        </td>
      </tr>
    `;
  }).join('');
}

function initDispenseModal() {
  // Populate dispense select
}

function openDispenseModal(itemId) {
  const item = DEMO_STORE.inventory.find(i => i.id === itemId);
  if (!item) return;

  document.getElementById('dispense-item-id').value = item.id;
  document.getElementById('dispense-med-name').textContent = `${item.name} (${item.batch})`;
  document.getElementById('dispense-available').textContent = item.quantity;
  document.getElementById('dispense-price').textContent = `₹${item.price.toFixed(2)}`;
  document.getElementById('dispense-qty').max = item.quantity;
  document.getElementById('dispense-qty').value = 1;

  openModal('dispense-modal');
}

async function handleDispenseSubmit(event) {
  event.preventDefault();

  const itemId = document.getElementById('dispense-item-id').value;
  const qty = parseInt(document.getElementById('dispense-qty').value, 10);

  if (isNaN(qty) || qty <= 0) {
    alert("Please enter a valid positive quantity to dispense.");
    return;
  }

  const result = await MedTrackDB.recordMedicineSale({
    inventory_id: itemId,
    quantity: qty
  });

  if (result.success) {
    alert(result.message);
    closeModal('dispense-modal');
    loadInventoryTable();
  } else {
    alert(`Dispense Error: ${result.message}`);
  }
}
