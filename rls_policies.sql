-- ============================================================================
-- MEDTRACK: REAL-TIME MULTI-BRANCH HOSPITAL MANAGEMENT SYSTEM
-- FILE: database/rls_policies.sql
-- PURPOSE: Supabase Row Level Security (RLS) policies for branch isolation & RBAC
-- ============================================================================

-- Enable RLS on all operational tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctor_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointment_cancellation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE medicine_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE medicine_sale_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_delivery_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- SECURITY DEFINER HELPER FUNCTIONS
-- Retrieve user role and branch from profiles safely without recursion
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_current_user_profile()
RETURNS TABLE (profile_id UUID, role VARCHAR, branch_id UUID) 
LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT id, role, branch_id 
    FROM profiles 
    WHERE auth_user_id = auth.uid() OR id = auth.uid()
    LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION current_user_role()
RETURNS VARCHAR LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT role FROM profiles WHERE auth_user_id = auth.uid() OR id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION current_user_branch_id()
RETURNS UUID LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT branch_id FROM profiles WHERE auth_user_id = auth.uid() OR id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION is_super_admin()
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER AS $$
    SELECT COALESCE((SELECT role = 'super_admin' FROM profiles WHERE auth_user_id = auth.uid() OR id = auth.uid() LIMIT 1), FALSE);
$$;

-- ----------------------------------------------------------------------------
-- 1. PROFILES POLICIES
-- ----------------------------------------------------------------------------
CREATE POLICY "Super admin can view all profiles"
    ON profiles FOR SELECT
    USING (is_super_admin());

CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth_user_id = auth.uid() OR id = auth.uid());

CREATE POLICY "Branch heads can view staff and doctors in their branch"
    ON profiles FOR SELECT
    USING (
        current_user_role() = 'branch_head' 
        AND branch_id = current_user_branch_id()
    );

-- ----------------------------------------------------------------------------
-- 2. PATIENTS POLICIES
-- ----------------------------------------------------------------------------
CREATE POLICY "Super Admin full access to patients"
    ON patients FOR ALL
    USING (is_super_admin());

CREATE POLICY "Branch Head can view branch patients"
    ON patients FOR SELECT
    USING (
        current_user_role() = 'branch_head' 
        AND registered_branch_id = current_user_branch_id()
    );

CREATE POLICY "Doctors and Receptionists can view patients in their branch"
    ON patients FOR SELECT
    USING (
        current_user_role() IN ('doctor', 'receptionist') 
        AND registered_branch_id = current_user_branch_id()
    );

CREATE POLICY "Receptionist can insert and update patient demographic data"
    ON patients FOR INSERT
    WITH CHECK (
        current_user_role() = 'receptionist' 
        AND registered_branch_id = current_user_branch_id()
    );

CREATE POLICY "Patients can view only their own record"
    ON patients FOR SELECT
    USING (
        profile_id IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid() OR id = auth.uid())
    );

-- ----------------------------------------------------------------------------
-- 3. APPOINTMENTS POLICIES
-- ----------------------------------------------------------------------------
CREATE POLICY "Super Admin full access to appointments"
    ON appointments FOR ALL
    USING (is_super_admin());

CREATE POLICY "Branch Head can view and manage branch appointments"
    ON appointments FOR ALL
    USING (
        current_user_role() = 'branch_head' 
        AND branch_id = current_user_branch_id()
    );

CREATE POLICY "Doctor can view and update assigned appointments"
    ON appointments FOR ALL
    USING (
        current_user_role() = 'doctor' 
        AND doctor_id IN (
            SELECT d.id FROM doctors d 
            JOIN profiles p ON d.profile_id = p.id 
            WHERE p.auth_user_id = auth.uid() OR p.id = auth.uid()
        )
    );

CREATE POLICY "Receptionist can manage branch appointments"
    ON appointments FOR ALL
    USING (
        current_user_role() = 'receptionist' 
        AND branch_id = current_user_branch_id()
    );

CREATE POLICY "Patient can view and book their own appointments"
    ON appointments FOR SELECT
    USING (
        patient_id IN (
            SELECT pt.id FROM patients pt
            JOIN profiles p ON pt.profile_id = p.id
            WHERE p.auth_user_id = auth.uid() OR p.id = auth.uid()
        )
    );

CREATE POLICY "Patient can insert appointment for themselves"
    ON appointments FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT pt.id FROM patients pt
            JOIN profiles p ON pt.profile_id = p.id
            WHERE p.auth_user_id = auth.uid() OR p.id = auth.uid()
        )
    );

-- ----------------------------------------------------------------------------
-- 4. CLINICAL MEDICAL RECORDS & CONSULTATIONS (Doctors & Patients Only)
-- Receptionists MUST NOT view clinical notes!
-- ----------------------------------------------------------------------------
CREATE POLICY "Super Admin view medical records"
    ON medical_records FOR SELECT
    USING (is_super_admin());

CREATE POLICY "Doctor can view and create medical records"
    ON medical_records FOR ALL
    USING (
        current_user_role() = 'doctor' 
        AND branch_id = current_user_branch_id()
    );

CREATE POLICY "Patients view own medical records"
    ON medical_records FOR SELECT
    USING (
        patient_id IN (
            SELECT pt.id FROM patients pt
            JOIN profiles p ON pt.profile_id = p.id
            WHERE p.auth_user_id = auth.uid() OR p.id = auth.uid()
        )
    );

CREATE POLICY "Doctor can manage consultations"
    ON consultations FOR ALL
    USING (
        current_user_role() = 'doctor' 
        AND doctor_id IN (
            SELECT d.id FROM doctors d 
            JOIN profiles p ON d.profile_id = p.id 
            WHERE p.auth_user_id = auth.uid() OR p.id = auth.uid()
        )
    );

CREATE POLICY "Patients view own consultations"
    ON consultations FOR SELECT
    USING (
        patient_id IN (
            SELECT pt.id FROM patients pt
            JOIN profiles p ON pt.profile_id = p.id
            WHERE p.auth_user_id = auth.uid() OR p.id = auth.uid()
        )
    );

-- ----------------------------------------------------------------------------
-- 5. PRESCRIPTIONS POLICIES
-- ----------------------------------------------------------------------------
CREATE POLICY "Super Admin view prescriptions"
    ON prescriptions FOR SELECT
    USING (is_super_admin());

CREATE POLICY "Doctor create and view prescriptions in branch"
    ON prescriptions FOR ALL
    USING (
        current_user_role() = 'doctor' 
        AND branch_id = current_user_branch_id()
    );

CREATE POLICY "Pharmacist view and dispense prescriptions"
    ON prescriptions FOR ALL
    USING (branch_id = current_user_branch_id());

CREATE POLICY "Patient view own prescriptions"
    ON prescriptions FOR SELECT
    USING (
        patient_id IN (
            SELECT pt.id FROM patients pt
            JOIN profiles p ON pt.profile_id = p.id
            WHERE p.auth_user_id = auth.uid() OR p.id = auth.uid()
        )
    );

-- ----------------------------------------------------------------------------
-- 6. INVENTORY POLICIES (Branch Head & Pharmacist branch isolation)
-- ----------------------------------------------------------------------------
CREATE POLICY "Super Admin full inventory access"
    ON inventory FOR ALL
    USING (is_super_admin());

CREATE POLICY "Branch staff view branch inventory"
    ON inventory FOR SELECT
    USING (branch_id = current_user_branch_id());

CREATE POLICY "Branch staff update branch inventory"
    ON inventory FOR UPDATE
    USING (branch_id = current_user_branch_id());

-- ----------------------------------------------------------------------------
-- 7. NOTIFICATIONS POLICIES
-- ----------------------------------------------------------------------------
CREATE POLICY "User can view and update own notifications"
    ON notifications FOR ALL
    USING (
        recipient_user_id IN (SELECT id FROM profiles WHERE auth_user_id = auth.uid() OR id = auth.uid())
    );

CREATE POLICY "Super Admin can view all notifications"
    ON notifications FOR SELECT
    USING (is_super_admin());

-- ----------------------------------------------------------------------------
-- 8. EMERGENCY EVENTS POLICIES
-- ----------------------------------------------------------------------------
CREATE POLICY "Super Admin full emergency control"
    ON emergency_events FOR ALL
    USING (is_super_admin());

CREATE POLICY "Branch Head can view and declare branch emergencies"
    ON emergency_events FOR ALL
    USING (
        current_user_role() = 'branch_head' 
        AND branch_id = current_user_branch_id()
    );

CREATE POLICY "Staff, Doctors and Patients can view active emergencies in branch"
    ON emergency_events FOR SELECT
    USING (branch_id = current_user_branch_id() OR is_super_admin());
