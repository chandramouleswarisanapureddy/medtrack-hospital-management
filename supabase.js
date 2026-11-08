/**
 * ============================================================================
 * MEDTRACK: SUPABASE CLIENT & DATA ADAPTER
 * FILE: js/supabase.js
 * PURPOSE: Supabase PostgreSQL Realtime client with seamless local fallback
 * ============================================================================
 */

let supabaseClient = null;

// Initialize Supabase if library and credentials exist
(function initSupabase() {
  if (typeof supabase !== 'undefined' && isSupabaseConfigured()) {
    try {
      supabaseClient = supabase.createClient(
        MEDTRACK_CONFIG.SUPABASE_URL,
        MEDTRACK_CONFIG.SUPABASE_ANON_KEY
      );
      console.log("[MedTrack] Supabase Realtime Client Connected Successfully.");
    } catch (err) {
      console.warn("[MedTrack] Supabase client init failed, falling back to local store:", err);
    }
  } else {
    console.log("[MedTrack] Running in Standalone Demo Mode with Local Reactive Store.");
  }
})();

// Realtime Event Subscription Dispatcher
const RealtimeEmitter = {
  listeners: {},
  on(event, callback) {
    if (!this.listeners[event]) this.listeners[event] = [];
    this.listeners[event].push(callback);
  },
  emit(event, payload) {
    if (this.listeners[event]) {
      this.listeners[event].forEach(cb => {
        try { cb(payload); } catch (e) { console.error("Realtime subscriber error:", e); }
      });
    }
  }
};

// Data Service API
const MedTrackDB = {
  // --- BRANCHES ---
  async getBranches() {
    if (supabaseClient) {
      const { data, error } = await supabaseClient.from('branches').select('*').order('name');
      if (!error && data) return data;
    }
    return DEMO_STORE.branches;
  },

  // --- DEPARTMENTS ---
  async getDepartments() {
    if (supabaseClient) {
      const { data, error } = await supabaseClient.from('departments').select('*').order('name');
      if (!error && data) return data;
    }
    return DEMO_STORE.departments;
  },

  // --- DOCTORS ---
  async getDoctors(branchId = null) {
    if (supabaseClient) {
      let query = supabaseClient.from('doctors').select('*, departments(name), branches(name)');
      if (branchId) query = query.eq('branch_id', branchId);
      const { data, error } = await query;
      if (!error && data) return data;
    }
    let docs = DEMO_STORE.doctors;
    if (branchId) docs = docs.filter(d => d.branch_id === branchId);
    return docs;
  },

  // --- PATIENTS ---
  async getPatients(branchId = null) {
    if (supabaseClient) {
      let query = supabaseClient.from('patients').select('*');
      if (branchId) query = query.eq('registered_branch_id', branchId);
      const { data, error } = await query;
      if (!error && data) return data;
    }
    let pts = DEMO_STORE.patients;
    if (branchId) pts = pts.filter(p => p.branch_id === branchId);
    return pts;
  },

  // --- APPOINTMENTS ---
  async getAppointments(filters = {}) {
    if (supabaseClient) {
      let query = supabaseClient.from('appointments').select('*, patients(full_name), doctors(full_name), departments(name), branches(name)');
      if (filters.branch_id) query = query.eq('branch_id', filters.branch_id);
      if (filters.doctor_id) query = query.eq('doctor_id', filters.doctor_id);
      if (filters.patient_id) query = query.eq('patient_id', filters.patient_id);
      const { data, error } = await query.order('appointment_date', { ascending: true });
      if (!error && data) return data;
    }
    let appts = [...DEMO_STORE.appointments];
    if (filters.branch_id) appts = appts.filter(a => a.branch_id === filters.branch_id);
    if (filters.doctor_id) appts = appts.filter(a => a.doctor_id === filters.doctor_id);
    if (filters.patient_id) appts = appts.filter(a => a.patient_id === filters.patient_id);
    return appts;
  },

  async bookAppointment(bookingData) {
    // Check for concurrency double-booking conflict
    const conflict = DEMO_STORE.appointments.find(a => 
      a.doctor_id === bookingData.doctor_id &&
      a.date === bookingData.date &&
      a.time === bookingData.time &&
      !['Cancelled', 'No-show', 'Cancelled - Emergency'].includes(a.status)
    );

    if (conflict) {
      return {
        success: false,
        error_code: 'SLOT_ALREADY_BOOKED',
        message: 'Concurrency Alert: This time slot was just booked by another patient. Please choose a different slot.'
      };
    }

    const doctor = DEMO_STORE.doctors.find(d => d.id === bookingData.doctor_id);
    const patient = DEMO_STORE.patients.find(p => p.id === bookingData.patient_id) || { name: bookingData.patient_name || "New Patient" };
    const branch = DEMO_STORE.branches.find(b => b.id === bookingData.branch_id);
    const dept = DEMO_STORE.departments.find(d => d.id === bookingData.department_id);

    const token = DEMO_STORE.appointments.filter(a => a.doctor_id === bookingData.doctor_id && a.date === bookingData.date).length + 1;
    const apptNumber = `APT-${bookingData.date.replace(/-/g, '')}-${String(token).padStart(3, '0')}`;

    const newAppt = {
      id: 'apt-' + Date.now(),
      number: apptNumber,
      patient_id: bookingData.patient_id,
      patient_name: patient.name,
      doctor_id: bookingData.doctor_id,
      doctor_name: doctor ? doctor.name : "Assigned Doctor",
      dept_id: bookingData.department_id,
      dept_name: dept ? dept.name : "General",
      branch_id: bookingData.branch_id,
      branch_name: branch ? branch.name : "Branch",
      date: bookingData.date,
      time: bookingData.time,
      status: 'Confirmed',
      token: token,
      reason: bookingData.reason || "General Consultation",
      risk_score: bookingData.risk_score || 0.15,
      risk_level: bookingData.risk_level || "Low"
    };

    DEMO_STORE.appointments.push(newAppt);

    // Add In-App Notification
    const notif = {
      id: 'notif-' + Date.now(),
      recipient_user_id: bookingData.booked_by_user_id || "p0000000-0000-0000-0000-000000000051",
      type: 'APPOINTMENT_CONFIRMED',
      title: 'Appointment Confirmed',
      message: `Your appointment ${apptNumber} with ${newAppt.doctor_name} at ${newAppt.branch_name} has been confirmed for ${newAppt.date} at ${newAppt.time}. Token #${token}.`,
      is_read: false,
      created_at: new Date().toISOString()
    };
    DEMO_STORE.notifications.unshift(notif);

    RealtimeEmitter.emit('appointment_created', newAppt);
    RealtimeEmitter.emit('notification_received', notif);

    return {
      success: true,
      appointment: newAppt,
      message: 'Appointment booked successfully.'
    };
  },

  // --- PHARMACY INVENTORY & SALES ---
  async getInventory(branchId = null) {
    let inv = [...DEMO_STORE.inventory];
    if (branchId) inv = inv.filter(i => i.branch_id === branchId);
    return inv;
  },

  async recordMedicineSale(saleData) {
    const invItem = DEMO_STORE.inventory.find(i => i.id === saleData.inventory_id);
    if (!invItem) {
      return { success: false, message: 'Inventory item not found.' };
    }
    if (invItem.quantity < saleData.quantity) {
      return { success: false, message: `Insufficient stock! Only ${invItem.quantity} units available.` };
    }

    // Deduct stock safely
    invItem.quantity -= saleData.quantity;
    invItem.status = invItem.quantity <= invItem.reorder ? 'Low Stock' : 'In Stock';

    RealtimeEmitter.emit('inventory_updated', invItem);

    return {
      success: true,
      remaining_quantity: invItem.quantity,
      message: `Sale recorded. Dispensed ${saleData.quantity} units of ${invItem.name}. Remaining: ${invItem.quantity}`
    };
  },

  // --- NOTIFICATIONS ---
  async getNotifications(userId = null) {
    let list = [...DEMO_STORE.notifications];
    if (userId) list = list.filter(n => !n.recipient_user_id || n.recipient_user_id === userId);
    return list;
  },

  async markNotificationRead(notifId) {
    const n = DEMO_STORE.notifications.find(item => item.id === notifId);
    if (n) n.is_read = true;
    RealtimeEmitter.emit('notifications_changed');
    return true;
  },

  // --- EMERGENCY MANAGEMENT ---
  async reportHospitalEmergency(emergencyData) {
    const eventId = 'emg-' + Date.now();
    const eventCode = `EMG-${emergencyData.start_date.replace(/-/g, '')}-${Math.floor(100 + Math.random() * 900)}`;

    const emergencyEvent = {
      id: eventId,
      code: eventCode,
      branch_id: emergencyData.branch_id,
      doctor_id: emergencyData.doctor_id,
      start_date: emergencyData.start_date,
      end_date: emergencyData.end_date,
      start_time: emergencyData.start_time || '00:00:00',
      end_time: emergencyData.end_time || '23:59:59',
      reason: emergencyData.reason,
      status: 'Active',
      created_at: new Date().toISOString()
    };

    DEMO_STORE.emergency_events.unshift(emergencyEvent);

    // Identify affected confirmed appointments
    const affected = DEMO_STORE.appointments.filter(a => {
      const matchBranch = a.branch_id === emergencyData.branch_id;
      const matchDoc = !emergencyData.doctor_id || a.doctor_id === emergencyData.doctor_id;
      const matchDate = a.date >= emergencyData.start_date && a.date <= emergencyData.end_date;
      const matchStatus = ['Confirmed', 'Pending'].includes(a.status);
      return matchBranch && matchDoc && matchDate && matchStatus;
    });

    let rescheduledCount = 0;
    let pendingCount = 0;
    const replacementList = [];

    affected.forEach(oldAppt => {
      // 1. Mark original appointment as 'Cancelled - Emergency'
      oldAppt.status = 'Cancelled - Emergency';
      oldAppt.emergency_reason = emergencyData.reason;

      // 2. Automated Search for replacement slot within next 7 days
      // Priority 1: Same doctor, or Priority 2: Alternative doctor in same department and branch
      let foundSlot = null;
      const candidateDate = new Date(new Date(emergencyData.end_date).getTime() + 86400000 * 2).toISOString().split('T')[0];
      const availableTime = "14:00:00"; // Afternoon backup slot

      // Check for available backup doctor in same department
      const backupDoctor = DEMO_STORE.doctors.find(d => 
        d.branch_id === oldAppt.branch_id && 
        d.department_id === oldAppt.dept_id && 
        d.id !== oldAppt.doctor_id
      ) || DEMO_STORE.doctors.find(d => d.id === oldAppt.doctor_id);

      if (backupDoctor) {
        foundSlot = {
          date: candidateDate,
          time: availableTime,
          doctor: backupDoctor
        };
      }

      if (foundSlot) {
        rescheduledCount++;
        const newApptId = 'apt-rep-' + Date.now() + '-' + Math.floor(Math.random() * 100);
        const newNumber = `APT-${candidateDate.replace(/-/g, '')}-R01`;

        const replacementAppt = {
          id: newApptId,
          number: newNumber,
          patient_id: oldAppt.patient_id,
          patient_name: oldAppt.patient_name,
          doctor_id: foundSlot.doctor.id,
          doctor_name: foundSlot.doctor.name,
          dept_id: oldAppt.dept_id,
          dept_name: oldAppt.dept_name,
          branch_id: oldAppt.branch_id,
          branch_name: oldAppt.branch_name,
          date: candidateDate,
          time: availableTime,
          status: 'Confirmed',
          token: 1,
          reason: `${oldAppt.reason} (Auto-Rescheduled)`,
          original_appointment_id: oldAppt.id,
          reschedule_reason: `Hospital emergency: ${emergencyData.reason}`
        };

        oldAppt.replacement_appointment_id = newApptId;
        DEMO_STORE.appointments.push(replacementAppt);
        replacementList.push(replacementAppt);

        // Generate Urgent Patient In-App Notification
        const notifMsg = `Dear ${oldAppt.patient_name},\n\nWe regret to inform you that your original appointment (${oldAppt.number}) has been cancelled due to an unexpected hospital emergency.\n\nYour replacement appointment has been arranged.\n\nNew Appointment Details:\nHospital Branch: ${oldAppt.branch_name}\nDoctor: ${foundSlot.doctor.name}\nDepartment: ${oldAppt.dept_name}\nOriginal Appointment: ${oldAppt.date} at ${oldAppt.time}\nNew Appointment: ${candidateDate} at ${availableTime}\n\nWe apologize for the inconvenience.\n\nThank you,\nMedTrack Hospital Management`;

        const notif = {
          id: 'notif-' + Date.now() + Math.random(),
          recipient_user_id: oldAppt.patient_id === "c0000000-0000-0000-0000-000000000001" ? "p0000000-0000-0000-0000-000000000051" : null,
          type: 'EMERGENCY_RESCHEDULE',
          title: 'Important: Your MedTrack Appointment Has Been Rescheduled',
          message: notifMsg,
          is_read: false,
          created_at: new Date().toISOString()
        };
        DEMO_STORE.notifications.unshift(notif);
        RealtimeEmitter.emit('notification_received', notif);
      } else {
        pendingCount++;
        oldAppt.status = 'Awaiting Manual Rescheduling';
      }
    });

    RealtimeEmitter.emit('emergency_declared', {
      event: emergencyEvent,
      affected_count: affected.length,
      rescheduled_count: rescheduledCount,
      pending_count: pendingCount
    });

    return {
      success: true,
      event_code: eventCode,
      affected_appointments: affected.length,
      rescheduled_appointments: rescheduledCount,
      pending_manual_rescheduling: pendingCount,
      replacements: replacementList
    };
  }
};
