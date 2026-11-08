# MedTrack: Academic Viva Questions & Detailed Model Answers

### Q1. What is the core problem MedTrack solves?
**Answer:** MedTrack solves multi-facility hospital fragmentation by centralizing patient medical histories, preventing appointment race conditions with database constraints, and providing automated emergency cancellation and replacement-slot discovery across three hospital branches.

### Q2. How is branch isolation enforced in the database?
**Answer:** Branch isolation is enforced using PostgreSQL Row Level Security (RLS) policies. For example, a Branch Head or Receptionist query is filtered with `WHERE branch_id = current_user_branch_id()`. The Super Admin possesses global access without branch filters.

### Q3. Why not use an in-memory lock (like Python Mutex) for the actual web booking system?
**Answer:** An in-memory mutex only synchronizes threads within a single operating system process on a single server. In a modern cloud-deployed web application (e.g. Netlify CDN + distributed clients), incoming requests arrive on different servers. Therefore, concurrency safety must be enforced at the database level using transactions and a partial unique index:
```sql
CREATE UNIQUE INDEX idx_unique_active_doctor_slot 
ON appointments(doctor_id, appointment_date, appointment_time)
WHERE status NOT IN ('Cancelled', 'No-show', 'Cancelled - Emergency');
```

### Q4. How does the automated emergency rescheduling algorithm work?
**Answer:** 
1. An authorized administrator specifies an affected branch, doctor, date, time window, and reason.
2. The database marks matching confirmed bookings as `'Cancelled - Emergency'`.
3. It searches for the earliest available replacement slot within the next 7 days, prioritizing:
   - Priority 1: Same doctor in the same branch.
   - Priority 2: Another doctor in the same department and branch.
4. If a slot is found, a replacement appointment is inserted and linked via foreign keys (`original_appointment_id` and `replacement_appointment_id`).
5. If no slot exists, the patient is flagged as `'Awaiting Manual Rescheduling'` and placed into an administrative queue.
6. An in-app notification with old vs. new appointment details is dispatched to the patient.

### Q5. What dataset was used in the Machine Learning module?
**Answer:** We used the Kaggle *Medical Appointment No Shows* dataset containing 110,527 clinical appointments. Key features include patient age, gender, scholarship welfare status, chronic conditions (hypertension, diabetes), SMS reminder receipt, booking lead time (days in advance), and appointment day-of-week.

### Q6. Which ML models did you evaluate and why?
**Answer:** We trained and compared Logistic Regression and Random Forest. Logistic Regression provides high clinical interpretability through learned feature coefficients (odds ratios), while Random Forest captures non-linear interactions between booking lead time and patient age. Evaluation was conducted using Accuracy, Precision, Recall, F1-Score, and ROC-AUC.

### Q7. How does the Data Engineering pipeline operate?
**Answer:** The pipeline implements an ETL architecture:
- **Extract:** Gathers operational appointment and pharmacy sales records across branches.
- **Transform:** Cleans data, expands date dimensions, and computes branch KPIs.
- **Validate:** Verifies assertions (such as non-negative inventory quantities and valid status enumerations).
- **Load:** Exports dimensional data marts (`fact_appointments.csv`, `dim_branch_performance.csv`) and generates markdown/JSON executive reports.

### Q8. Why did you normalize the database to 3NF?
**Answer:** Normalization eliminates insertion, deletion, and update anomalies.
- **1NF:** Atomic values and no repeating groups (e.g. discrete rows in `prescription_items`).
- **2NF:** No partial dependencies on composite keys (e.g. separating medicine batches from branch inventory).
- **3NF:** No transitive dependencies (e.g. separating department attributes from doctor records).

### Q9. How do you prevent negative inventory during medicine sales?
**Answer:** Two safeguards:
1. Database check constraint: `CHECK (quantity_available >= 0)`.
2. Stored procedure transaction using `SELECT ... FOR UPDATE` to lock inventory rows before decrementing.

### Q10. What is a Race Condition in the context of Operating Systems?
**Answer:** A race condition occurs when multiple concurrent threads or processes access and manipulate shared data concurrently, and the final outcome depends on the non-deterministic order of execution and thread preemption. In `os_demo/concurrent_booking.py`, we demonstrate two threads simultaneously reading a slot as available before either writes a booked status, causing a double-booking bug when unsynchronized.
