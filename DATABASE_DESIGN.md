# MedTrack Multi-Branch Hospital: Database Architecture & Design Specification

## 1. Relational Database Management System (RDBMS)
- **Engine:** PostgreSQL 15+ (Hosted on Supabase)
- **Extensions:** `uuid-ossp`, `pgcrypto`
- **Time Zone:** Asia/Kolkata (Indian Standard Time, UTC+05:30)

## 2. Relational Schema Data Dictionary

### Core Tables
1. **`branches`**: Physical hospital premises (`BRANCH-A`, `BRANCH-B`, `BRANCH-C`).
2. **`profiles`**: User master tying Supabase Auth UUID to roles (`super_admin`, `branch_head`, `doctor`, `receptionist`, `patient`).
3. **`departments`**: Clinical medical departments (Cardiology, Orthopedics, Pediatrics, General Medicine, Neurology, Dermatology).
4. **`patients`**: Demographics, contact info, blood group, allergies, registered branch.
5. **`doctors`**: Qualifications, specialization, consultation fees, license number, branch association.
6. **`doctor_schedules`**: Day-of-week recurrence, consultation time window, slot duration (30 mins).
7. **`appointments`**: Master appointment registry with partial unique index, status machine, and emergency auto-reschedule pointers.
8. **`emergency_events`**: Disruption incidents (doctor emergency, facility repair, quarantine) triggering batch auto-rescheduling.
9. **`appointment_cancellation_history`**: Audit trail of cancellations, reason logs, and replacement records.
10. **`medical_records` & `consultations`**: Clinical encounters, symptoms, physical examination, vitals, diagnosis, follow-up dates.
11. **`prescriptions` & `prescription_items`**: Medical scripts linked to consultations and inventory catalog.
12. **`medicines`, `suppliers`, `medicine_batches`**: Master pharmaceutical catalog and lot tracking.
13. **`inventory`**: Physical on-hand quantities per branch with `quantity_available >= 0` check constraint.
14. **`medicine_sales` & `medicine_sale_items`**: Billing and dispensing register.
15. **`stock_transactions`**: Double-entry ledger of all inventory increments and decrements.
16. **`notifications` & `notification_delivery_logs`**: Multi-channel in-app, SMS, and email dispatch audit.
17. **`audit_logs`**: Immutable security ledger of all high-privilege operations.

## 3. Concurrency & Constraint Safety Strategy

### Double-Booking Prevention: Partial Unique Index
Traditional web apps suffer from race conditions when two clients check slot availability simultaneously. In MedTrack, the database enforces mutual exclusion at the storage engine level:

```sql
CREATE UNIQUE INDEX idx_unique_active_doctor_slot 
ON appointments (doctor_id, appointment_date, appointment_time)
WHERE status NOT IN ('Cancelled', 'No-show', 'Cancelled - Emergency');
```
This guarantees:
- Two active reservations for the same doctor at the same minute will be rejected by the database engine with unique constraint violation `23505`.
- Cancelled or rescheduled slots immediately become available for other patients without artificial locks.

### Inventory Non-Negative Constraint & Pessimistic Locking
```sql
ALTER TABLE inventory ADD CONSTRAINT check_stock_non_negative CHECK (quantity_available >= 0);
```
During sales dispensing, `SELECT ... FOR UPDATE` acquires row-level locks on the target medicine inventory rows, preventing concurrent over-dispensation.

## 4. Multi-Branch Isolation & Row Level Security (RLS)
- **Super Admin:** Global visibility across all 3 branches.
- **Branch Head:** Isolated strictly to their branch records (`branch_id = current_user_branch_id()`).
- **Doctor:** Restricted to their clinical consultations, assigned appointments, and branch pharmacy stock.
- **Receptionist:** Permitted to view and register demographic data and manage scheduling; prohibited from reading confidential doctor clinical notes and diagnoses.
- **Patient:** Restricted via `patient_id` to only their own appointments, prescriptions, and medical reports.
