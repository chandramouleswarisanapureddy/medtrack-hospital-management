# MedTrack: Database Normalization Analysis (1NF, 2NF, 3NF)

## 1. Academic Normalization Overview
Normalization is a systematic database design technique that decomposes tables to eliminate data redundancy and undesirable modification anomalies (Insertion, Deletion, and Update anomalies).

In MedTrack, all operational tables have been normalized to **Third Normal Form (3NF)** while preserving dependency preservation and lossless joins.

---

## 2. Unnormalized Form (UNF) & Relational Anomalies

Consider an unnormalized single flat spreadsheet table commonly found in legacy clinic management:

```text
CLINIC_RECORDS_UNF(
    PatientID, PatientName, PatientPhone, BranchName, BranchCity,
    DoctorID, DoctorName, DoctorDept, ConsultationFee,
    AppointmentDate, AppointmentTime, MedicineName, Dosage, UnitPrice
)
```

### Modification Anomalies in UNF:
1. **Insertion Anomaly:** Cannot record a new doctor or branch without first booking a patient appointment (since `PatientID` or `AppointmentDate` forms part of the primary key).
2. **Deletion Anomaly:** If the only patient visiting a doctor cancels and their row is deleted, all records of the doctor's name, specialization, and branch assignment are lost.
3. **Update Anomaly:** If a doctor increases their consultation fee from ₹500 to ₹700, dozens of historical rows must be updated. Any missed row results in data inconsistency.

---

## 3. First Normal Form (1NF)

### 1NF Definition
A relation is in 1NF if and only if:
- All attribute values are atomic (indivisible single values).
- There are no repeating groups or multi-valued arrays.
- Each row is uniquely identifiable by a Primary Key.

### Application in MedTrack:
- **Violation:** A patient record containing comma-separated medicines: `Paracetamol, Amoxicillin, Cetirizine` in a single column violates 1NF.
- **Decomposition:** Split into distinct atomic tables: `prescriptions` and `prescription_items`, where each row in `prescription_items` stores exactly one medicine reference and dosage.

```sql
-- 1NF Compliant Prescription Items Table
CREATE TABLE prescription_items (
    id UUID PRIMARY KEY,
    prescription_id UUID REFERENCES prescriptions(id),
    medicine_id UUID REFERENCES medicines(id),
    dosage VARCHAR(50) NOT NULL,
    frequency VARCHAR(50) NOT NULL,
    total_quantity INT NOT NULL
);
```

---

## 4. Second Normal Form (2NF)

### 2NF Definition
A relation is in 2NF if and only if:
- It is in 1NF.
- Every non-prime attribute is **fully functionally dependent** on the whole primary key (No partial functional dependency on any composite key subset).

### Application in MedTrack:
Consider a composite key inventory table: `INVENTORY(BranchID, MedicineID, BatchNumber, BranchCity, ExpiryDate, Quantity)`:
- Composite Primary Key: `(BranchID, MedicineID, BatchNumber)`
- Dependency 1: `BranchID -> BranchCity` (Partial Dependency! `BranchCity` depends only on `BranchID`, not on the entire primary key).
- Dependency 2: `(MedicineID, BatchNumber) -> ExpiryDate` (Partial Dependency! `ExpiryDate` depends only on the medicine batch).

### 2NF Decomposition in MedTrack:
We decompose into three fully dependent relations:
1. `branches(id, code, name, city, phone)` - `city` depends on `branch_id`.
2. `medicine_batches(id, medicine_id, batch_number, expiry_date)` - `expiry_date` depends on batch.
3. `inventory(id, branch_id, medicine_id, batch_id, quantity_available)` - `quantity_available` is fully dependent on the combination of branch, medicine, and batch.

---

## 5. Third Normal Form (3NF)

### 3NF Definition
A relation is in 3NF if and only if:
- It is in 2NF.
- No non-prime attribute is transitively dependent on the primary key (No transitive dependency: $X \rightarrow Y$ and $Y \rightarrow Z$, where $X$ is primary key and $Z$ is non-prime).

### Application in MedTrack:
Consider a doctor relation: `DOCTORS(DoctorID, DoctorName, DepartmentID, DepartmentName, DepartmentIcon)`:
- Primary Key: `DoctorID`
- Functional Dependency 1: `DoctorID -> DepartmentID`
- Functional Dependency 2: `DepartmentID -> DepartmentName, DepartmentIcon`
- Transitive Dependency: `DoctorID -> DepartmentName` via `DepartmentID`.

If the name of the Cardiology department is modified, multiple doctor records must be altered.

### 3NF Decomposition in MedTrack:
Decomposed into:
1. `departments(id, code, name, description, icon)`
2. `doctors(id, doctor_identifier, full_name, department_id, branch_id, specialization, consultation_fee)`

Here, non-prime attributes of `doctors` depend directly and solely on the primary key `DoctorID`. All transitive dependencies are eliminated.

---

## 6. Summary of Normalized Schema Benefits

| Normal Form | Target Eliminated | MedTrack Relational Benefit |
|---|---|---|
| **1NF** | Multi-valued attributes & repeating groups | Normalized prescriptions and discrete dosage instructions. |
| **2NF** | Partial functional dependencies | Isolated physical branch details and medicine batch expiries. |
| **3NF** | Transitive dependencies | Decoupled departments from doctor records and patient profiles from auth logins. |
| **Performance** | Redundant storage overhead | Clean indexing, minimal update locks, and high concurrency throughput. |
