-- ============================================================================
-- MEDTRACK: REAL-TIME MULTI-BRANCH HOSPITAL MANAGEMENT SYSTEM
-- FILE: database/seed.sql
-- PURPOSE: Realistic synthetic seed data for academic demonstration & evaluation
-- ============================================================================

-- Variables / Static UUIDs for relational consistency across branches
-- Branch A: Metro Central
-- Branch B: Tech City
-- Branch C: Green Valley

-- ----------------------------------------------------------------------------
-- 1. INSERT BRANCHES
-- ----------------------------------------------------------------------------
INSERT INTO branches (id, code, name, address, city, state, postal_code, phone, email) VALUES
('a0000000-0000-0000-0000-000000000001', 'BRANCH-A', 'MedTrack Metro Central', '45 Healthcare Boulevard, MG Road', 'Bengaluru', 'Karnataka', '560001', '+91 80 2234 5678', 'metro.central@medtrack.org'),
('a0000000-0000-0000-0000-000000000002', 'BRANCH-B', 'MedTrack Tech City', '12 Electronic City Phase 1', 'Bengaluru', 'Karnataka', '560100', '+91 80 4455 6677', 'tech.city@medtrack.org'),
('a0000000-0000-0000-0000-000000000003', 'BRANCH-C', 'MedTrack Green Valley', '88 Whitefield Main Road', 'Bengaluru', 'Karnataka', '560066', '+91 80 6677 8899', 'green.valley@medtrack.org')
ON CONFLICT (code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2. INSERT DEPARTMENTS
-- ----------------------------------------------------------------------------
INSERT INTO departments (id, code, name, description, icon) VALUES
('d0000000-0000-0000-0000-000000000001', 'CARDIO', 'Cardiology', 'Heart health, cardiac evaluation, and cardiovascular disease management', 'heart-pulse'),
('d0000000-0000-0000-0000-000000000002', 'ORTHO', 'Orthopedics', 'Musculoskeletal system, bone fractures, joints, and spine care', 'bone'),
('d0000000-0000-0000-0000-000000000003', 'PEDIATRICS', 'Pediatrics', 'Comprehensive child healthcare, immunizations, and pediatric wellness', 'baby'),
('d0000000-0000-0000-0000-000000000004', 'GENMED', 'General Medicine', 'Primary care, fever management, diabetes, and preventive medicine', 'stethoscope'),
('d0000000-0000-0000-0000-000000000005', 'NEURO', 'Neurology', 'Brain disorders, stroke management, headaches, and neurological testing', 'brain'),
('d0000000-0000-0000-0000-000000000006', 'DERMA', 'Dermatology', 'Skin disorders, allergies, cosmetic dermatology, and wound recovery', 'shield')
ON CONFLICT (code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 3. INSERT PROFILES (ROLES: super_admin, branch_head, doctor, receptionist, patient)
-- ----------------------------------------------------------------------------
INSERT INTO profiles (id, email, full_name, role, branch_id, phone) VALUES
-- Super Admin (Centralized Hospital Head)
('p0000000-0000-0000-0000-000000000001', 'head.admin@medtrack.org', 'Dr. Arvind Swaminathan', 'super_admin', NULL, '+91 98450 11001'),

-- Branch Heads
('p0000000-0000-0000-0000-000000000002', 'head.brancha@medtrack.org', 'Dr. Ramesh Kulkarni', 'branch_head', 'a0000000-0000-0000-0000-000000000001', '+91 98450 11002'),
('p0000000-0000-0000-0000-000000000003', 'head.branchb@medtrack.org', 'Dr. Meera Nambiar', 'branch_head', 'a0000000-0000-0000-0000-000000000002', '+91 98450 11003'),
('p0000000-0000-0000-0000-000000000004', 'head.branchc@medtrack.org', 'Dr. Farooq Siddiqui', 'branch_head', 'a0000000-0000-0000-0000-000000000003', '+91 98450 11004'),

-- Doctors
('p0000000-0000-0000-0000-000000000011', 'dr.rajesh.sharma@medtrack.org', 'Dr. Rajesh Sharma', 'doctor', 'a0000000-0000-0000-0000-000000000001', '+91 98450 22001'),
('p0000000-0000-0000-0000-000000000012', 'dr.priya.nair@medtrack.org', 'Dr. Priya Nair', 'doctor', 'a0000000-0000-0000-0000-000000000001', '+91 98450 22002'),
('p0000000-0000-0000-0000-000000000013', 'dr.ananya.deshmukh@medtrack.org', 'Dr. Ananya Deshmukh', 'doctor', 'a0000000-0000-0000-0000-000000000001', '+91 98450 22003'),
('p0000000-0000-0000-0000-000000000014', 'dr.vikram.reddy@medtrack.org', 'Dr. Vikram Reddy', 'doctor', 'a0000000-0000-0000-0000-000000000002', '+91 98450 22004'),
('p0000000-0000-0000-0000-000000000015', 'dr.sneha.iyer@medtrack.org', 'Dr. Sneha Iyer', 'doctor', 'a0000000-0000-0000-0000-000000000002', '+91 98450 22005'),
('p0000000-0000-0000-0000-000000000016', 'dr.amit.chatterjee@medtrack.org', 'Dr. Amit Chatterjee', 'doctor', 'a0000000-0000-0000-0000-000000000003', '+91 98450 22006'),

-- Receptionists / Staff
('p0000000-0000-0000-0000-000000000031', 'reception.brancha@medtrack.org', 'Kavita Menon', 'receptionist', 'a0000000-0000-0000-0000-000000000001', '+91 98450 33001'),
('p0000000-0000-0000-0000-000000000032', 'reception.branchb@medtrack.org', 'Sunil Jadhav', 'receptionist', 'a0000000-0000-0000-0000-000000000002', '+91 98450 33002'),
('p0000000-0000-0000-0000-000000000033', 'reception.branchc@medtrack.org', 'Ayesha Khan', 'receptionist', 'a0000000-0000-0000-0000-000000000003', '+91 98450 33003'),

-- Patients
('p0000000-0000-0000-0000-000000000051', 'rahul.verma@example.com', 'Rahul Verma', 'patient', 'a0000000-0000-0000-0000-000000000001', '+91 98765 43210'),
('p0000000-0000-0000-0000-000000000052', 'deepa.shankar@example.com', 'Deepa Shankar', 'patient', 'a0000000-0000-0000-0000-000000000001', '+91 98765 43211'),
('p0000000-0000-0000-0000-000000000053', 'karthik.subramanian@example.com', 'Karthik Subramanian', 'patient', 'a0000000-0000-0000-0000-000000000002', '+91 98765 43212')
ON CONFLICT (email) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 4. INSERT DOCTORS
-- ----------------------------------------------------------------------------
INSERT INTO doctors (id, profile_id, doctor_identifier, full_name, department_id, branch_id, specialization, qualification, experience_years, license_number, phone, email, consultation_fee, is_available) VALUES
('b0000000-0000-0000-0000-000000000001', 'p0000000-0000-0000-0000-000000000011', 'MED-DOC-001', 'Dr. Rajesh Sharma', 'd0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Interventional Cardiology', 'MBBS, MD, DM (Cardiology)', 15, 'KMC-DOC-44819', '+91 98450 22001', 'dr.rajesh.sharma@medtrack.org', 800.00, TRUE),
('b0000000-0000-0000-0000-000000000002', 'p0000000-0000-0000-0000-000000000012', 'MED-DOC-002', 'Dr. Priya Nair', 'd0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'Internal Medicine & Diabetology', 'MBBS, MD (General Medicine)', 10, 'KMC-DOC-51203', '+91 98450 22002', 'dr.priya.nair@medtrack.org', 600.00, TRUE),
('b0000000-0000-0000-0000-000000000003', 'p0000000-0000-0000-0000-000000000013', 'MED-DOC-003', 'Dr. Ananya Deshmukh', 'd0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Pediatric Care & Neonatology', 'MBBS, DCH, DNB (Pediatrics)', 8, 'KMC-DOC-62941', '+91 98450 22003', 'dr.ananya.deshmukh@medtrack.org', 500.00, TRUE),
('b0000000-0000-0000-0000-000000000004', 'p0000000-0000-0000-0000-000000000014', 'MED-DOC-004', 'Dr. Vikram Reddy', 'd0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'Orthopedic Surgery & Sports Medicine', 'MBBS, MS (Ortho)', 12, 'KMC-DOC-48762', '+91 98450 22004', 'dr.vikram.reddy@medtrack.org', 750.00, TRUE),
('b0000000-0000-0000-0000-000000000005', 'p0000000-0000-0000-0000-000000000015', 'MED-DOC-005', 'Dr. Sneha Iyer', 'd0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000002', 'Clinical & Aesthetic Dermatology', 'MBBS, MD (Dermatology)', 9, 'KMC-DOC-55318', '+91 98450 22005', 'dr.sneha.iyer@medtrack.org', 650.00, TRUE),
('b0000000-0000-0000-0000-000000000006', 'p0000000-0000-0000-0000-000000000016', 'MED-DOC-006', 'Dr. Amit Chatterjee', 'd0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000003', 'Neurology & Stroke Rehabilitation', 'MBBS, DM (Neurology)', 14, 'KMC-DOC-41904', '+91 98450 22006', 'dr.amit.chatterjee@medtrack.org', 900.00, TRUE),
-- Additional doctor in Cardiology at Branch A for emergency replacement demonstrating department backup!
('b0000000-0000-0000-0000-000000000007', NULL, 'MED-DOC-007', 'Dr. Sandeep Hegde', 'd0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Non-Invasive Cardiology', 'MBBS, MD, DNB (Cardiology)', 11, 'KMC-DOC-49912', '+91 98450 22007', 'dr.sandeep.hegde@medtrack.org', 750.00, TRUE)
ON CONFLICT (doctor_identifier) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 5. INSERT STAFF
-- ----------------------------------------------------------------------------
INSERT INTO staff (id, profile_id, staff_identifier, full_name, role, department_id, branch_id, phone, email, shift_timing) VALUES
('s0000000-0000-0000-0000-000000000001', 'p0000000-0000-0000-0000-000000000031', 'STF-001', 'Kavita Menon', 'Receptionist', 'd0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', '+91 98450 33001', 'reception.brancha@medtrack.org', '08:00 - 16:00'),
('s0000000-0000-0000-0000-000000000002', 'p0000000-0000-0000-0000-000000000032', 'STF-002', 'Sunil Jadhav', 'Receptionist', 'd0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', '+91 98450 33002', 'reception.branchb@medtrack.org', '09:00 - 17:00'),
('s0000000-0000-0000-0000-000000000003', 'p0000000-0000-0000-0000-000000000033', 'STF-003', 'Ayesha Khan', 'Receptionist', 'd0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000003', '+91 98450 33003', 'reception.branchc@medtrack.org', '08:30 - 16:30'),
('s0000000-0000-0000-0000-000000000004', NULL, 'STF-004', 'Joseph Anthony', 'Pharmacist', NULL, 'a0000000-0000-0000-0000-000000000001', '+91 98450 33004', 'pharmacy.brancha@medtrack.org', '08:00 - 20:00'),
('s0000000-0000-0000-0000-000000000005', NULL, 'STF-005', 'Geeta Sundaram', 'Nurse', 'd0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', '+91 98450 33005', 'geeta.nurse@medtrack.org', '07:00 - 15:00')
ON CONFLICT (staff_identifier) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 6. INSERT DOCTOR SCHEDULES (Operating Monday to Saturday: days 1 to 6)
-- ----------------------------------------------------------------------------
INSERT INTO doctor_schedules (doctor_id, day_of_week, start_time, end_time, slot_duration_minutes) VALUES
-- Dr. Rajesh Sharma (Cardio Branch A) - Mon, Wed, Fri (9am - 1pm)
('b0000000-0000-0000-0000-000000000001', 1, '09:00:00', '13:00:00', 30),
('b0000000-0000-0000-0000-000000000001', 3, '09:00:00', '13:00:00', 30),
('b0000000-0000-0000-0000-000000000001', 5, '09:00:00', '13:00:00', 30),

-- Dr. Priya Nair (Gen Med Branch A) - Mon to Fri (10am - 2pm)
('b0000000-0000-0000-0000-000000000002', 1, '10:00:00', '14:00:00', 30),
('b0000000-0000-0000-0000-000000000002', 2, '10:00:00', '14:00:00', 30),
('b0000000-0000-0000-0000-000000000002', 3, '10:00:00', '14:00:00', 30),
('b0000000-0000-0000-0000-000000000002', 4, '10:00:00', '14:00:00', 30),
('b0000000-0000-0000-0000-000000000002', 5, '10:00:00', '14:00:00', 30),

-- Dr. Sandeep Hegde (Backup Cardio Branch A) - Mon to Sat (14:00 - 18:00)
('b0000000-0000-0000-0000-000000000007', 1, '14:00:00', '18:00:00', 30),
('b0000000-0000-0000-0000-000000000007', 2, '14:00:00', '18:00:00', 30),
('b0000000-0000-0000-0000-000000000007', 3, '14:00:00', '18:00:00', 30),
('b0000000-0000-0000-0000-000000000007', 4, '14:00:00', '18:00:00', 30),
('b0000000-0000-0000-0000-000000000007', 5, '14:00:00', '18:00:00', 30)
ON CONFLICT (doctor_id, day_of_week, start_time) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 7. INSERT PATIENTS (Synthetic patient records)
-- ----------------------------------------------------------------------------
INSERT INTO patients (id, profile_id, patient_identifier, full_name, date_of_birth, gender, blood_group, phone, email, address, allergies, medical_history_summary, registered_branch_id) VALUES
('c0000000-0000-0000-0000-000000000001', 'p0000000-0000-0000-0000-000000000051', 'MED-PAT-101', 'Rahul Verma', '1988-06-15', 'Male', 'B+', '+91 98765 43210', 'rahul.verma@example.com', 'Flat 304, Palm Meadows, Indiranagar, Bengaluru', 'Penicillin', 'Mild Hypertension diagnosed in 2021', 'a0000000-0000-0000-0000-000000000001'),
('c0000000-0000-0000-0000-000000000002', 'p0000000-0000-0000-0000-000000000052', 'MED-PAT-102', 'Deepa Shankar', '1994-11-22', 'Female', 'O+', '+91 98765 43211', 'deepa.shankar@example.com', 'Villa 18, Prestige Oasis, Doddaballapur Road', 'Sulfa drugs', 'Type-2 Diabetes on oral Metformin', 'a0000000-0000-0000-0000-000000000001'),
('c0000000-0000-0000-0000-000000000003', 'p0000000-0000-0000-0000-000000000053', 'MED-PAT-103', 'Karthik Subramanian', '1975-03-08', 'Male', 'A+', '+91 98765 43212', 'karthik.subramanian@example.com', '52/3, 5th Cross, Malleshwaram, Bengaluru', 'None reported', 'Chronic Lower Back Pain, Lumbar spondylosis', 'a0000000-0000-0000-0000-000000000002'),
('c0000000-0000-0000-0000-000000000004', NULL, 'MED-PAT-104', 'Anil Mehta', '1962-09-14', 'Male', 'AB+', '+91 98765 43213', 'anil.mehta@example.com', '201 Lakeview Apts, Bellandur, Bengaluru', 'Aspirin', 'Coronary artery disease, Stent placed in 2018', 'a0000000-0000-0000-0000-000000000001'),
('c0000000-0000-0000-0000-000000000005', NULL, 'MED-PAT-105', 'Sunita Rao', '2001-04-30', 'Female', 'O-', '+91 98765 43214', 'sunita.rao@example.com', '402 Greenwoods, Whitefield, Bengaluru', 'Pollen, Dust', 'Seasonal Allergic Rhinitis and Asthma', 'a0000000-0000-0000-0000-000000000003')
ON CONFLICT (patient_identifier) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 8. INSERT SUPPLIERS & MEDICINES
-- ----------------------------------------------------------------------------
INSERT INTO suppliers (id, name, contact_person, phone, email, address) VALUES
('sup00000-0000-0000-0000-000000000001', 'Apex Medico Distributors', 'Girish Patel', '+91 98200 44551', 'sales@apexmedico.in', 'Peenya Industrial Area Phase 2, Bengaluru'),
('sup00000-0000-0000-0000-000000000002', 'Karnataka Pharma Logistics', 'Venkatesh Rao', '+91 98200 44552', 'orders@karnatakapharma.com', 'Koramangala 4th Block, Bengaluru')
ON CONFLICT DO NOTHING;

INSERT INTO medicines (id, item_code, name, generic_name, category, dosage_form, strength, unit_price, reorder_level, description) VALUES
('m0000000-0000-0000-0000-000000000001', 'MED-001', 'Paracetamol 650', 'Paracetamol', 'Antipyretics', 'Tablet', '650 mg', 3.50, 50, 'Antipyretic and analgesic for fever and pain relief'),
('m0000000-0000-0000-0000-000000000002', 'MED-002', 'Amoxicillin & Clavulanate 625', 'Amoxicillin + Clavulanic Acid', 'Antibiotics', 'Tablet', '625 mg', 18.00, 30, 'Broad-spectrum antibiotic for bacterial infections'),
('m0000000-0000-0000-0000-000000000003', 'MED-003', 'Atorvastatin 20', 'Atorvastatin Calcium', 'Cardiac', 'Tablet', '20 mg', 12.50, 40, 'Lipid-lowering medication for cholesterol management'),
('m0000000-0000-0000-0000-000000000004', 'MED-004', 'Metformin Hydrochloride 500', 'Metformin HCl', 'Antidiabetics', 'Tablet', '500 mg', 4.00, 60, 'First-line medication for Type 2 diabetes'),
('m0000000-0000-0000-0000-000000000005', 'MED-005', 'Telmisartan 40', 'Telmisartan', 'Antihypertensives', 'Tablet', '40 mg', 9.00, 35, 'Angiotensin II receptor blocker for hypertension'),
('m0000000-0000-0000-0000-000000000006', 'MED-006', 'Cetirizine 10', 'Cetirizine Hydrochloride', 'Antihistamines', 'Tablet', '10 mg', 2.80, 50, 'Second-generation antihistamine for allergic reactions'),
('m0000000-0000-0000-0000-000000000007', 'MED-007', 'Pantoprazole 40', 'Pantoprazole Sodium', 'Analgesics', 'Tablet', '40 mg', 7.50, 40, 'Proton pump inhibitor for gastric acidity and GERD'),
('m0000000-0000-0000-0000-000000000008', 'MED-008', 'Azithromycin 500', 'Azithromycin', 'Antibiotics', 'Tablet', '500 mg', 22.00, 25, 'Macrolide antibiotic for respiratory tract infections')
ON CONFLICT (item_code) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 9. INSERT MEDICINE BATCHES
-- ----------------------------------------------------------------------------
INSERT INTO medicine_batches (id, medicine_id, batch_number, supplier_id, manufacturing_date, expiry_date, purchase_price, selling_price) VALUES
('bch00000-0000-0000-0000-000000000001', 'm0000000-0000-0000-0000-000000000001', 'PCM-2024-B1', 'sup00000-0000-0000-0000-000000000001', '2024-01-15', '2027-01-14', 2.00, 3.50),
('bch00000-0000-0000-0000-000000000002', 'm0000000-0000-0000-0000-000000000002', 'AMX-2024-B3', 'sup00000-0000-0000-0000-000000000001', '2024-03-10', '2026-03-09', 12.00, 18.00),
('bch00000-0000-0000-0000-000000000003', 'm0000000-0000-0000-0000-000000000003', 'ATV-2024-B8', 'sup00000-0000-0000-0000-000000000002', '2024-02-01', '2026-12-31', 8.00, 12.50),
('bch00000-0000-0000-0000-000000000004', 'm0000000-0000-0000-0000-000000000004', 'MET-2023-B2', 'sup00000-0000-0000-0000-000000000002', '2023-11-20', '2026-11-19', 2.50, 4.00),
('bch00000-0000-0000-0000-000000000005', 'm0000000-0000-0000-0000-000000000005', 'TEL-2024-B5', 'sup00000-0000-0000-0000-000000000002', '2024-05-12', '2027-05-11', 5.50, 9.00)
ON CONFLICT (medicine_id, batch_number) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 10. INSERT INVENTORY (Branch-specific stock levels with low-stock tests)
-- ----------------------------------------------------------------------------
INSERT INTO inventory (id, branch_id, medicine_id, batch_id, quantity_available, reserved_quantity) VALUES
-- Branch A: Metro Central
('inv00000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'm0000000-0000-0000-0000-000000000001', 'bch00000-0000-0000-0000-000000000001', 350, 10),
('inv00000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'm0000000-0000-0000-0000-000000000002', 'bch00000-0000-0000-0000-000000000002', 15, 0), -- Low stock alert triggered (< 30)
('inv00000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'm0000000-0000-0000-0000-000000000003', 'bch00000-0000-0000-0000-000000000003', 180, 5),

-- Branch B: Tech City
('inv00000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000002', 'm0000000-0000-0000-0000-000000000001', 'bch00000-0000-0000-0000-000000000001', 200, 0),
('inv00000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000002', 'm0000000-0000-0000-0000-000000000004', 'bch00000-0000-0000-0000-000000000004', 120, 0),

-- Branch C: Green Valley
('inv00000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000003', 'm0000000-0000-0000-0000-000000000001', 'bch00000-0000-0000-0000-000000000001', 140, 0),
('inv00000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000003', 'm0000000-0000-0000-0000-000000000005', 'bch00000-0000-0000-0000-000000000005', 8, 0) -- Low stock alert (< 35)
ON CONFLICT (branch_id, medicine_id, batch_id) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 11. INSERT SAMPLE APPOINTMENTS
-- ----------------------------------------------------------------------------
INSERT INTO appointments (
    id, appointment_number, patient_id, doctor_id, branch_id, department_id,
    appointment_date, appointment_time, status, reason_for_visit, token_number,
    no_show_risk_score, no_show_risk_level
) VALUES
-- Past Completed Appointment
('apt00000-0000-0000-0000-000000000001', 'APT-20261101-001', 'c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', '2026-11-01', '09:30:00', 'Completed', 'Routine Cardiac Evaluation', 1, 0.1240, 'Low'),

-- Upcoming Confirmed Appointments (Scheduled for next available clinic dates)
('apt00000-0000-0000-0000-000000000002', 'APT-20261109-001', 'c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', '2026-11-09', '10:00:00', 'Confirmed', 'Chest Discomfort Checkup', 2, 0.1850, 'Low'),
('apt00000-0000-0000-0000-000000000003', 'APT-20261109-002', 'c0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', '2026-11-09', '10:30:00', 'Confirmed', 'Post-Stent Follow-up', 3, 0.2210, 'Low'),
('apt00000-0000-0000-0000-000000000004', 'APT-20261109-003', 'c0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000004', '2026-11-09', '11:00:00', 'Confirmed', 'High Blood Sugar & Fatigue', 1, 0.3540, 'Medium')
ON CONFLICT (appointment_number) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 12. INSERT CONSULTATION & PRESCRIPTION FOR COMPLETED APPOINTMENT
-- ----------------------------------------------------------------------------
INSERT INTO medical_records (id, patient_id, record_number, record_date, title, category, created_by_doctor_id, branch_id) VALUES
('mr000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'REC-20261101-01', '2026-11-01', 'Cardiology Consultation Report', 'Consultation', 'b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001')
ON CONFLICT (record_number) DO NOTHING;

INSERT INTO consultations (id, consultation_number, appointment_id, medical_record_id, patient_id, doctor_id, branch_id, symptoms, examination_notes, diagnosis, doctor_notes, vitals_bp, vitals_pulse, vitals_temp_f, vitals_spo2, follow_up_date) VALUES
('con00000-0000-0000-0000-000000000001', 'CNS-20261101-01', 'apt00000-0000-0000-0000-000000000001', 'mr000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Occasional palpitations and slight exertion breathlessness', 'S1, S2 audible, normal sinus rhythm, no murmurs detected', 'Stage 1 Essential Hypertension with mild dyslipidemia', 'Advised 30 minutes daily brisk walk and low sodium diet', '134/86', 74, 98.4, 99, '2026-12-01')
ON CONFLICT (consultation_number) DO NOTHING;

INSERT INTO prescriptions (id, prescription_number, consultation_id, patient_id, doctor_id, branch_id, prescription_date, special_instructions) VALUES
('rx000000-0000-0000-0000-000000000001', 'RX-20261101-01', 'con00000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', '2026-11-01', 'Take after breakfast with plenty of water')
ON CONFLICT (prescription_number) DO NOTHING;

INSERT INTO prescription_items (prescription_id, medicine_id, dosage, frequency, duration_days, total_quantity, instructions) VALUES
('rx000000-0000-0000-0000-000000000001', 'm0000000-0000-0000-0000-000000000005', '1 tablet', 'Once daily morning', 30, 30, 'Monitor BP weekly'),
('rx000000-0000-0000-0000-000000000001', 'm0000000-0000-0000-0000-000000000003', '1 tablet', 'Once daily at bedtime', 30, 30, 'Lipid profile retest in 6 weeks')
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 13. INSERT SAMPLE NOTIFICATIONS
-- ----------------------------------------------------------------------------
INSERT INTO notifications (id, recipient_user_id, patient_id, branch_id, notification_type, title, message, is_read, related_appointment_id) VALUES
('notif000-0000-0000-0000-000000000001', 'p0000000-0000-0000-0000-000000000051', 'c0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'APPOINTMENT_CONFIRMED', 'Appointment Confirmed', 'Your appointment APT-20261109-001 with Dr. Rajesh Sharma at MedTrack Metro Central has been confirmed for 09 Nov 2026 at 10:00 AM.', FALSE, 'apt00000-0000-0000-0000-000000000002')
ON CONFLICT DO NOTHING;
