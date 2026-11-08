/**
 * ============================================================================
 * MEDTRACK: CONFIGURATION & DEMO STATE
 * FILE: js/config.js
 * PURPOSE: Supabase credentials, environment constants & operational state
 * ============================================================================
 */

const MEDTRACK_CONFIG = {
  // Supabase Project Credentials (Fill with your project details)
  // These are public client keys safe for browser exposure with RLS.
  // NEVER put service_role secret key in frontend code.
  SUPABASE_URL: "https://your-project.supabase.co", 
  SUPABASE_ANON_KEY: "your-anon-publishable-key",
  
  // Deployment Site Information
  APP_NAME: "MedTrack Hospital System",
  NETLIFY_DEPLOY_URL: "https://luminous-starburst-5ce75d.netlify.app",
  DEFAULT_TIMEZONE: "Asia/Kolkata",
  
  // Initial Academic Demo Roles
  ROLES: {
    SUPER_ADMIN: {
      id: "p0000000-0000-0000-0000-000000000001",
      email: "head.admin@medtrack.org",
      name: "Dr. Arvind Swaminathan",
      role: "super_admin",
      branch_id: null,
      branch_name: "All Branches (Central Oversight)"
    },
    BRANCH_HEAD_A: {
      id: "p0000000-0000-0000-0000-000000000002",
      email: "head.brancha@medtrack.org",
      name: "Dr. Ramesh Kulkarni",
      role: "branch_head",
      branch_id: "a0000000-0000-0000-0000-000000000001",
      branch_name: "Branch A (Metro Central)"
    },
    DOCTOR_SHARMA: {
      id: "p0000000-0000-0000-0000-000000000011",
      doctor_id: "b0000000-0000-0000-0000-000000000001",
      email: "dr.rajesh.sharma@medtrack.org",
      name: "Dr. Rajesh Sharma",
      role: "doctor",
      department: "Cardiology",
      branch_id: "a0000000-0000-0000-0000-000000000001",
      branch_name: "Branch A (Metro Central)"
    },
    RECEPTIONIST_A: {
      id: "p0000000-0000-0000-0000-000000000031",
      email: "reception.brancha@medtrack.org",
      name: "Kavita Menon",
      role: "receptionist",
      branch_id: "a0000000-0000-0000-0000-000000000001",
      branch_name: "Branch A (Metro Central)"
    },
    PATIENT_RAHUL: {
      id: "p0000000-0000-0000-0000-000000000051",
      patient_id: "c0000000-0000-0000-0000-000000000001",
      email: "rahul.verma@example.com",
      name: "Rahul Verma",
      role: "patient",
      branch_id: "a0000000-0000-0000-0000-000000000001",
      branch_name: "Branch A (Metro Central)"
    }
  }
};

// Realistic Multi-Branch Seed Data Store (Enables Instant Demonstration & Offline Testing)
const DEMO_STORE = {
  branches: [
    { id: "a0000000-0000-0000-0000-000000000001", code: "BRANCH-A", name: "MedTrack Metro Central", city: "Bengaluru", address: "45 Healthcare Boulevard, MG Road", phone: "+91 80 2234 5678", email: "metro.central@medtrack.org" },
    { id: "a0000000-0000-0000-0000-000000000002", code: "BRANCH-B", name: "MedTrack Tech City", city: "Bengaluru", address: "12 Electronic City Phase 1", phone: "+91 80 4455 6677", email: "tech.city@medtrack.org" },
    { id: "a0000000-0000-0000-0000-000000000003", code: "BRANCH-C", name: "MedTrack Green Valley", city: "Bengaluru", address: "88 Whitefield Main Road", phone: "+91 80 6677 8899", email: "green.valley@medtrack.org" }
  ],
  departments: [
    { id: "d0000000-0000-0000-0000-000000000001", code: "CARDIO", name: "Cardiology", icon: "heart-pulse", description: "Comprehensive heart health and cardiovascular diagnostics." },
    { id: "d0000000-0000-0000-0000-000000000002", code: "ORTHO", name: "Orthopedics", icon: "bone", description: "Joint replacements, fracture repair, and spine surgery." },
    { id: "d0000000-0000-0000-0000-000000000003", code: "PEDIATRICS", name: "Pediatrics", icon: "baby", description: "Child wellness, immunizations, and pediatric care." },
    { id: "d0000000-0000-0000-0000-000000000004", code: "GENMED", name: "General Medicine", icon: "stethoscope", description: "Primary care, diabetes management, and preventive health." },
    { id: "d0000000-0000-0000-0000-000000000005", code: "NEURO", name: "Neurology", icon: "brain", description: "Brain disorders, stroke recovery, and neurology." },
    { id: "d0000000-0000-0000-0000-000000000006", code: "DERMA", name: "Dermatology", icon: "shield", description: "Clinical skin therapy, dermatology, and wound healing." }
  ],
  doctors: [
    { id: "b0000000-0000-0000-0000-000000000001", identifier: "MED-DOC-001", name: "Dr. Rajesh Sharma", department_id: "d0000000-0000-0000-0000-000000000001", dept_name: "Cardiology", branch_id: "a0000000-0000-0000-0000-000000000001", branch_name: "Branch A", specialization: "Interventional Cardiology", fee: 800, experience: 15, available: true, phone: "+91 98450 22001", email: "dr.rajesh.sharma@medtrack.org" },
    { id: "b0000000-0000-0000-0000-000000000002", identifier: "MED-DOC-002", name: "Dr. Priya Nair", department_id: "d0000000-0000-0000-0000-000000000004", dept_name: "General Medicine", branch_id: "a0000000-0000-0000-0000-000000000001", branch_name: "Branch A", specialization: "Internal Medicine & Diabetology", fee: 600, experience: 10, available: true, phone: "+91 98450 22002", email: "dr.priya.nair@medtrack.org" },
    { id: "b0000000-0000-0000-0000-000000000007", identifier: "MED-DOC-007", name: "Dr. Sandeep Hegde", department_id: "d0000000-0000-0000-0000-000000000001", dept_name: "Cardiology", branch_id: "a0000000-0000-0000-0000-000000000001", branch_name: "Branch A", specialization: "Non-Invasive Cardiology", fee: 750, experience: 11, available: true, phone: "+91 98450 22007", email: "dr.sandeep.hegde@medtrack.org" },
    { id: "b0000000-0000-0000-0000-000000000004", identifier: "MED-DOC-004", name: "Dr. Vikram Reddy", department_id: "d0000000-0000-0000-0000-000000000002", dept_name: "Orthopedics", branch_id: "a0000000-0000-0000-0000-000000000002", branch_name: "Branch B", specialization: "Orthopedic Surgery", fee: 750, experience: 12, available: true, phone: "+91 98450 22004", email: "dr.vikram.reddy@medtrack.org" },
    { id: "b0000000-0000-0000-0000-000000000005", identifier: "MED-DOC-005", name: "Dr. Sneha Iyer", department_id: "d0000000-0000-0000-0000-000000000006", dept_name: "Dermatology", branch_id: "a0000000-0000-0000-0000-000000000002", branch_name: "Branch B", specialization: "Clinical Dermatology", fee: 650, experience: 9, available: true, phone: "+91 98450 22005", email: "dr.sneha.iyer@medtrack.org" },
    { id: "b0000000-0000-0000-0000-000000000006", identifier: "MED-DOC-006", name: "Dr. Amit Chatterjee", department_id: "d0000000-0000-0000-0000-000000000005", dept_name: "Neurology", branch_id: "a0000000-0000-0000-0000-000000000003", branch_name: "Branch C", specialization: "Stroke Neurology", fee: 900, experience: 14, available: true, phone: "+91 98450 22006", email: "dr.amit.chatterjee@medtrack.org" }
  ],
  patients: [
    { id: "c0000000-0000-0000-0000-000000000001", identifier: "MED-PAT-101", name: "Rahul Verma", dob: "1988-06-15", gender: "Male", blood_group: "B+", phone: "+91 98765 43210", email: "rahul.verma@example.com", allergies: "Penicillin", history: "Mild Hypertension diagnosed in 2021", branch_id: "a0000000-0000-0000-0000-000000000001" },
    { id: "c0000000-0000-0000-0000-000000000002", identifier: "MED-PAT-102", name: "Deepa Shankar", dob: "1994-11-22", gender: "Female", blood_group: "O+", phone: "+91 98765 43211", email: "deepa.shankar@example.com", allergies: "Sulfa drugs", history: "Type-2 Diabetes on Metformin", branch_id: "a0000000-0000-0000-0000-000000000001" },
    { id: "c0000000-0000-0000-0000-000000000003", identifier: "MED-PAT-103", name: "Karthik Subramanian", dob: "1975-03-08", gender: "Male", blood_group: "A+", phone: "+91 98765 43212", email: "karthik.subramanian@example.com", allergies: "None", history: "Lumbar spondylosis", branch_id: "a0000000-0000-0000-0000-000000000002" },
    { id: "c0000000-0000-0000-0000-000000000004", identifier: "MED-PAT-104", name: "Anil Mehta", dob: "1962-09-14", gender: "Male", blood_group: "AB+", phone: "+91 98765 43213", email: "anil.mehta@example.com", allergies: "Aspirin", history: "Coronary artery disease, Stent placed in 2018", branch_id: "a0000000-0000-0000-0000-000000000001" }
  ],
  appointments: [
    { id: "apt-001", number: "APT-20261109-001", patient_id: "c0000000-0000-0000-0000-000000000001", patient_name: "Rahul Verma", doctor_id: "b0000000-0000-0000-0000-000000000001", doctor_name: "Dr. Rajesh Sharma", dept_id: "d0000000-0000-0000-0000-000000000001", dept_name: "Cardiology", branch_id: "a0000000-0000-0000-0000-000000000001", branch_name: "Branch A", date: "2026-11-09", time: "10:00:00", status: "Confirmed", token: 1, reason: "Chest discomfort checkup", risk_score: 0.18, risk_level: "Low" },
    { id: "apt-002", number: "APT-20261109-002", patient_id: "c0000000-0000-0000-0000-000000000004", patient_name: "Anil Mehta", doctor_id: "b0000000-0000-0000-0000-000000000001", doctor_name: "Dr. Rajesh Sharma", dept_id: "d0000000-0000-0000-0000-000000000001", dept_name: "Cardiology", branch_id: "a0000000-0000-0000-0000-000000000001", branch_name: "Branch A", date: "2026-11-09", time: "10:30:00", status: "Confirmed", token: 2, reason: "Post-stent cardiac evaluation", risk_score: 0.22, risk_level: "Low" },
    { id: "apt-003", number: "APT-20261109-003", patient_id: "c0000000-0000-0000-0000-000000000002", patient_name: "Deepa Shankar", doctor_id: "b0000000-0000-0000-0000-000000000002", doctor_name: "Dr. Priya Nair", dept_id: "d0000000-0000-0000-0000-000000000004", dept_name: "General Medicine", branch_id: "a0000000-0000-0000-0000-000000000001", branch_name: "Branch A", date: "2026-11-09", time: "11:00:00", status: "Confirmed", token: 1, reason: "High blood sugar & fatigue", risk_score: 0.35, risk_level: "Medium" }
  ],
  inventory: [
    { id: "inv-001", branch_id: "a0000000-0000-0000-0000-000000000001", branch_name: "Branch A", code: "MED-001", name: "Paracetamol 650", category: "Antipyretics", batch: "PCM-2024-B1", quantity: 350, reorder: 50, price: 3.50, expiry: "2027-01-14", status: "In Stock" },
    { id: "inv-002", branch_id: "a0000000-0000-0000-0000-000000000001", branch_name: "Branch A", code: "MED-002", name: "Amoxicillin 625", category: "Antibiotics", batch: "AMX-2024-B3", quantity: 15, reorder: 30, price: 18.00, expiry: "2026-03-09", status: "Low Stock" },
    { id: "inv-003", branch_id: "a0000000-0000-0000-0000-000000000001", branch_name: "Branch A", code: "MED-003", name: "Atorvastatin 20", category: "Cardiac", batch: "ATV-2024-B8", quantity: 180, reorder: 40, price: 12.50, expiry: "2026-12-31", status: "In Stock" },
    { id: "inv-004", branch_id: "a0000000-0000-0000-0000-000000000002", branch_name: "Branch B", code: "MED-004", name: "Metformin 500", category: "Antidiabetics", batch: "MET-2023-B2", quantity: 120, reorder: 60, price: 4.00, expiry: "2026-11-19", status: "In Stock" },
    { id: "inv-005", branch_id: "a0000000-0000-0000-0000-000000000003", branch_name: "Branch C", code: "MED-005", name: "Telmisartan 40", category: "Antihypertensives", batch: "TEL-2024-B5", quantity: 8, reorder: 35, price: 9.00, expiry: "2027-05-11", status: "Low Stock" }
  ],
  notifications: [
    {
      id: "notif-001",
      recipient_user_id: "p0000000-0000-0000-0000-000000000051",
      type: "APPOINTMENT_CONFIRMED",
      title: "Appointment Confirmed",
      message: "Your appointment APT-20261109-001 with Dr. Rajesh Sharma at MedTrack Metro Central is confirmed for 09 Nov 2026 at 10:00 AM. Token #1.",
      is_read: false,
      created_at: new Date(Date.now() - 3600000).toISOString()
    }
  ],
  emergency_events: []
};

// Check if live Supabase credentials are configured
function isSupabaseConfigured() {
  return MEDTRACK_CONFIG.SUPABASE_URL && 
         MEDTRACK_CONFIG.SUPABASE_URL !== "https://your-project.supabase.co" &&
         MEDTRACK_CONFIG.SUPABASE_ANON_KEY && 
         MEDTRACK_CONFIG.SUPABASE_ANON_KEY !== "your-anon-publishable-key";
}
