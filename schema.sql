-- ============================================================================
-- MEDTRACK: REAL-TIME MULTI-BRANCH HOSPITAL MANAGEMENT SYSTEM
-- FILE: database/schema.sql
-- PURPOSE: Complete normalized PostgreSQL schema with constraints, indexes & audit
-- ============================================================================

-- Enable pgcrypto / uuid-ossp for cryptographic UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Clean drop for idempotence during academic testing (in reverse dependency order)
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS notification_delivery_logs CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS stock_transactions CASCADE;
DROP TABLE IF EXISTS medicine_sale_items CASCADE;
DROP TABLE IF EXISTS medicine_sales CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS medicine_batches CASCADE;
DROP TABLE IF EXISTS medicines CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS prescription_items CASCADE;
DROP TABLE IF EXISTS prescriptions CASCADE;
DROP TABLE IF EXISTS consultations CASCADE;
DROP TABLE IF EXISTS medical_records CASCADE;
DROP TABLE IF EXISTS appointment_cancellation_history CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS emergency_events CASCADE;
DROP TABLE IF EXISTS doctor_schedules CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS patients CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS branches CASCADE;

-- ----------------------------------------------------------------------------
-- 1. BRANCHES TABLE
-- Three physical branches: Branch A, Branch B, Branch C
-- ----------------------------------------------------------------------------
CREATE TABLE branches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(10) NOT NULL UNIQUE, -- 'BRANCH-A', 'BRANCH-B', 'BRANCH-C'
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL DEFAULT 'Karnataka',
    postal_code VARCHAR(10) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 2. USER PROFILES TABLE (Mirrors Supabase auth.users or standalone demo users)
-- ----------------------------------------------------------------------------
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE, -- References auth.users(id) in Supabase
    email VARCHAR(150) NOT NULL UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    role VARCHAR(30) NOT NULL CHECK (role IN ('super_admin', 'branch_head', 'doctor', 'receptionist', 'patient')),
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL, -- NULL for super_admin
    phone VARCHAR(20),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 3. DEPARTMENTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50) DEFAULT 'hospital',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 4. PATIENTS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    patient_identifier VARCHAR(20) NOT NULL UNIQUE, -- e.g. MED-PAT-1001
    full_name VARCHAR(120) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
    blood_group VARCHAR(5) CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(120),
    address TEXT,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    allergies TEXT DEFAULT 'None reported',
    medical_history_summary TEXT,
    registered_branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 5. DOCTORS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE doctors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    doctor_identifier VARCHAR(20) NOT NULL UNIQUE, -- e.g. MED-DOC-2001
    full_name VARCHAR(120) NOT NULL,
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    specialization VARCHAR(100) NOT NULL,
    qualification VARCHAR(100) NOT NULL,
    experience_years INT NOT NULL DEFAULT 1 CHECK (experience_years >= 0),
    license_number VARCHAR(50) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(120) NOT NULL,
    consultation_fee NUMERIC(10, 2) NOT NULL DEFAULT 500.00 CHECK (consultation_fee >= 0),
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 6. STAFF TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE staff (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    staff_identifier VARCHAR(20) NOT NULL UNIQUE,
    full_name VARCHAR(120) NOT NULL,
    role VARCHAR(40) NOT NULL CHECK (role IN ('Receptionist', 'Nurse', 'Pharmacist', 'Lab Technician', 'Branch Head', 'Administrator')),
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(120) NOT NULL,
    shift_timing VARCHAR(50) DEFAULT '09:00 - 17:00',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 7. DOCTOR SCHEDULES TABLE
-- Weekly recurring or specific slots
-- ----------------------------------------------------------------------------
CREATE TABLE doctor_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sun, 1=Mon, ..., 6=Sat
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_duration_minutes INT NOT NULL DEFAULT 30 CHECK (slot_duration_minutes > 0),
    max_patients_per_slot INT NOT NULL DEFAULT 1 CHECK (max_patients_per_slot = 1),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT check_schedule_times CHECK (end_time > start_time),
    UNIQUE (doctor_id, day_of_week, start_time)
);

-- ----------------------------------------------------------------------------
-- 8. EMERGENCY EVENTS TABLE
-- Captures hospital emergencies causing cancellation and auto-rescheduling
-- ----------------------------------------------------------------------------
CREATE TABLE emergency_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_identifier VARCHAR(30) NOT NULL UNIQUE, -- e.g. EMG-20261108-01
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    department_id UUID REFERENCES departments(id) ON DELETE SET NULL,
    doctor_id UUID REFERENCES doctors(id) ON DELETE SET NULL, -- NULL means entire branch or department affected
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    start_time TIME NOT NULL DEFAULT '00:00:00',
    end_time TIME NOT NULL DEFAULT '23:59:59',
    severity VARCHAR(20) NOT NULL DEFAULT 'High' CHECK (severity IN ('Low', 'Medium', 'High', 'Critical')),
    reason TEXT NOT NULL,
    action_taken TEXT,
    reported_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Resolved', 'Cancelled')),
    affected_appointments_count INT NOT NULL DEFAULT 0,
    rescheduled_count INT NOT NULL DEFAULT 0,
    pending_reschedule_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- ----------------------------------------------------------------------------
-- 9. APPOINTMENTS TABLE
-- Centralized table with concurrency safety constraint and emergency linking
-- ----------------------------------------------------------------------------
CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_number VARCHAR(30) NOT NULL UNIQUE, -- e.g. APT-20261108-001
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    department_id UUID NOT NULL REFERENCES departments(id) ON DELETE RESTRICT,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    duration_minutes INT NOT NULL DEFAULT 30,
    status VARCHAR(30) NOT NULL DEFAULT 'Confirmed' 
        CHECK (status IN ('Pending', 'Confirmed', 'Completed', 'Cancelled', 'No-show', 'Rescheduled', 'Cancelled - Emergency', 'Awaiting Manual Rescheduling')),
    reason_for_visit TEXT NOT NULL DEFAULT 'General Consultation',
    token_number INT,
    booked_by_role VARCHAR(30) NOT NULL DEFAULT 'patient',
    booked_by_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    
    -- Emergency rescheduling linkage
    emergency_event_id UUID REFERENCES emergency_events(id) ON DELETE SET NULL,
    original_appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    replacement_appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    reschedule_reason TEXT,
    
    -- Machine Learning Risk assessment (scored at creation/update)
    no_show_risk_score NUMERIC(5, 4), -- e.g. 0.1850 (18.5%)
    no_show_risk_level VARCHAR(15) CHECK (no_show_risk_level IN ('Low', 'Medium', 'High')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- CONCURRENCY SAFETY CONSTRAINT:
-- Prevents two active bookings for the same doctor at the same date and time!
-- Cancelled, No-show, and Cancelled - Emergency free up the slot for other bookings.
CREATE UNIQUE INDEX idx_unique_active_doctor_slot 
ON appointments (doctor_id, appointment_date, appointment_time)
WHERE status NOT IN ('Cancelled', 'No-show', 'Cancelled - Emergency');

-- ----------------------------------------------------------------------------
-- 10. APPOINTMENT CANCELLATION HISTORY TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE appointment_cancellation_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
    cancelled_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    cancelled_by_role VARCHAR(30) NOT NULL,
    cancellation_type VARCHAR(30) NOT NULL CHECK (cancellation_type IN ('Patient Request', 'Doctor Unavailable', 'Emergency Cancellation', 'Administrative', 'No-Show Recorded')),
    cancellation_reason TEXT NOT NULL,
    replacement_offered BOOLEAN NOT NULL DEFAULT FALSE,
    replacement_appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    cancelled_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 11. MEDICAL RECORDS & CONSULTATIONS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE medical_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    record_number VARCHAR(30) NOT NULL UNIQUE,
    record_date DATE NOT NULL DEFAULT CURRENT_DATE,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL DEFAULT 'Consultation' CHECK (category IN ('Consultation', 'Lab Report', 'Radiology', 'Discharge Summary', 'Vaccination')),
    created_by_doctor_id UUID REFERENCES doctors(id) ON DELETE SET NULL,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE consultations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    consultation_number VARCHAR(30) NOT NULL UNIQUE,
    appointment_id UUID UNIQUE REFERENCES appointments(id) ON DELETE RESTRICT,
    medical_record_id UUID REFERENCES medical_records(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    consultation_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    symptoms TEXT NOT NULL,
    examination_notes TEXT,
    diagnosis TEXT NOT NULL,
    doctor_notes TEXT,
    vitals_bp VARCHAR(20),
    vitals_pulse INT,
    vitals_temp_f NUMERIC(4, 1),
    vitals_spo2 INT,
    follow_up_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 12. PRESCRIPTIONS & PRESCRIPTION ITEMS
-- ----------------------------------------------------------------------------
CREATE TABLE prescriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_number VARCHAR(30) NOT NULL UNIQUE,
    consultation_id UUID REFERENCES consultations(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES doctors(id) ON DELETE RESTRICT,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    prescription_date DATE NOT NULL DEFAULT CURRENT_DATE,
    special_instructions TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'Issued' CHECK (status IN ('Issued', 'Partially Dispensed', 'Dispensed', 'Cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 13. PHARMACY: SUPPLIERS & MEDICINES
-- ----------------------------------------------------------------------------
CREATE TABLE suppliers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL,
    contact_person VARCHAR(100),
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    address TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE medicines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_code VARCHAR(30) NOT NULL UNIQUE, -- e.g. MED-001
    name VARCHAR(150) NOT NULL,
    generic_name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL CHECK (category IN ('Antibiotics', 'Analgesics', 'Antipyretics', 'Antihypertensives', 'Antidiabetics', 'Antihistamines', 'Vitamins & Supplements', 'Cardiac', 'Topical', 'Other')),
    dosage_form VARCHAR(30) NOT NULL CHECK (dosage_form IN ('Tablet', 'Capsule', 'Syrup', 'Injection', 'Ointment', 'Drops', 'Inhaler')),
    strength VARCHAR(50) NOT NULL, -- e.g. '500 mg', '10 ml'
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    reorder_level INT NOT NULL DEFAULT 20 CHECK (reorder_level >= 0),
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE prescription_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prescription_id UUID NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
    medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE RESTRICT,
    dosage VARCHAR(50) NOT NULL, -- e.g. '1 tablet'
    frequency VARCHAR(50) NOT NULL, -- e.g. 'Twice daily after meals'
    duration_days INT NOT NULL CHECK (duration_days > 0),
    total_quantity INT NOT NULL CHECK (total_quantity > 0),
    dispensed_quantity INT NOT NULL DEFAULT 0 CHECK (dispensed_quantity <= total_quantity),
    instructions TEXT
);

-- ----------------------------------------------------------------------------
-- 14. PHARMACY: BATCHES, INVENTORY & TRANSACTIONS
-- ----------------------------------------------------------------------------
CREATE TABLE medicine_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
    batch_number VARCHAR(50) NOT NULL,
    supplier_id UUID REFERENCES suppliers(id) ON DELETE SET NULL,
    manufacturing_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    purchase_price NUMERIC(10, 2) NOT NULL CHECK (purchase_price >= 0),
    selling_price NUMERIC(10, 2) NOT NULL CHECK (selling_price >= purchase_price),
    CONSTRAINT check_dates CHECK (expiry_date > manufacturing_date),
    UNIQUE (medicine_id, batch_number)
);

CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE RESTRICT,
    batch_id UUID NOT NULL REFERENCES medicine_batches(id) ON DELETE RESTRICT,
    quantity_available INT NOT NULL DEFAULT 0 CHECK (quantity_available >= 0),
    reserved_quantity INT NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0),
    last_restocked_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (branch_id, medicine_id, batch_id)
);

-- ----------------------------------------------------------------------------
-- 15. PHARMACY: SALES & DISPENSING
-- ----------------------------------------------------------------------------
CREATE TABLE medicine_sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_number VARCHAR(30) NOT NULL UNIQUE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    patient_id UUID REFERENCES patients(id) ON DELETE SET NULL,
    prescription_id UUID REFERENCES prescriptions(id) ON DELETE SET NULL,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (discount_amount >= 0),
    net_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (net_amount >= 0),
    payment_method VARCHAR(20) NOT NULL DEFAULT 'Cash' CHECK (payment_method IN ('Cash', 'Card', 'UPI', 'Insurance')),
    sold_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    sale_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE medicine_sale_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sale_id UUID NOT NULL REFERENCES medicine_sales(id) ON DELETE CASCADE,
    inventory_id UUID NOT NULL REFERENCES inventory(id) ON DELETE RESTRICT,
    medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE RESTRICT,
    batch_id UUID NOT NULL REFERENCES medicine_batches(id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    total_price NUMERIC(10, 2) NOT NULL CHECK (total_price >= 0)
);

CREATE TABLE stock_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_code VARCHAR(30) NOT NULL UNIQUE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
    medicine_id UUID NOT NULL REFERENCES medicines(id) ON DELETE RESTRICT,
    batch_id UUID NOT NULL REFERENCES medicine_batches(id) ON DELETE RESTRICT,
    transaction_type VARCHAR(30) NOT NULL CHECK (transaction_type IN ('PURCHASE_RECEIPT', 'SALE_DISPENSE', 'DAMAGE_WRITE_OFF', 'BRANCH_TRANSFER_IN', 'BRANCH_TRANSFER_OUT', 'AUDIT_CORRECTION')),
    quantity INT NOT NULL, -- Positive for in, negative for out
    reference_id UUID, -- References sale_id or transfer_id
    notes TEXT,
    performed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    transaction_date TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 16. NOTIFICATIONS & DELIVERY LOGS
-- ----------------------------------------------------------------------------
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    notification_type VARCHAR(40) NOT NULL CHECK (notification_type IN (
        'EMERGENCY_RESCHEDULE',
        'APPOINTMENT_CONFIRMED',
        'APPOINTMENT_CANCELLED',
        'REMINDER_NO_SHOW_RISK',
        'LOW_STOCK_ALERT',
        'PRESCRIPTION_ISSUED'
    )),
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    related_appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    related_emergency_id UUID REFERENCES emergency_events(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE notification_delivery_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    channel VARCHAR(20) NOT NULL CHECK (channel IN ('IN_APP', 'EMAIL', 'SMS')),
    recipient_address VARCHAR(150) NOT NULL, -- Email or phone number
    delivery_status VARCHAR(20) NOT NULL CHECK (delivery_status IN ('SENT', 'DELIVERED', 'FAILED', 'QUEUED', 'SIMULATED')),
    provider_response TEXT,
    attempt_count INT NOT NULL DEFAULT 1,
    dispatched_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 17. AUDIT LOGS TABLE
-- Complete audit trail for security and academic operating system compliance
-- ----------------------------------------------------------------------------
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    table_name VARCHAR(50) NOT NULL,
    record_id UUID NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'EMERGENCY_TRIGGER', 'STOCK_DISPENSE')),
    old_data JSONB,
    new_data JSONB,
    performed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    branch_id UUID REFERENCES branches(id) ON DELETE SET NULL,
    ip_address VARCHAR(45),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- PERFORMANCE INDEXES
-- ----------------------------------------------------------------------------
CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor ON appointments(doctor_id);
CREATE INDEX idx_appointments_branch ON appointments(branch_id);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_inventory_branch_med ON inventory(branch_id, medicine_id);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_user_id, is_read);
CREATE INDEX idx_medical_records_patient ON medical_records(patient_id);
CREATE INDEX idx_consultations_patient ON consultations(patient_id);
CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX idx_emergency_branch ON emergency_events(branch_id, status);

-- Schema documentation comment
COMMENT ON TABLE appointments IS 'Stores all hospital appointments with concurrency unique index preventing double-booking.';
COMMENT ON TABLE emergency_events IS 'Stores hospital emergencies that trigger automated rescheduling.';
COMMENT ON TABLE inventory IS 'Branch-isolated medicine stock quantities with strictly non-negative constraints.';
