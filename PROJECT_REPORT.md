# ACADEMIC PROJECT REPORT
## MEDTRACK: REAL-TIME MULTI-BRANCH HOSPITAL MANAGEMENT SYSTEM
**Degree:** Bachelor of Technology (B.Tech) in Computer Science and Engineering (Data Science)  
**Academic Year:** 2026  

---

### 1. ABSTRACT
Modern healthcare delivery across multi-facility networks suffers from data fragmentation, paper records, scheduling conflicts, and sudden disruptions caused by clinical emergencies. **MedTrack** is a centralized, real-time hospital management system architected to unify operations across three distinct hospital branches (Branch A - Metro Central, Branch B - Tech City, and Branch C - Green Valley) under a single cohesive web portal. 

MedTrack integrates five key computer science and data science disciplines:
1. **Relational Database Management Systems (RDBMS):** A 3NF normalized PostgreSQL schema with partial unique indexes preventing concurrent slot double-booking, transaction-safe inventory tracking, and Row Level Security (RLS) enforcing branch-level isolation.
2. **Special Emergency Management System:** An automated emergency cancellation engine that detects affected appointments, marks original bookings as cancelled, automatically discovers optimal replacement slots prioritizing the same doctor and department within the branch, and notifies patients via in-app alerts and delivery logs.
3. **Machine Learning:** A predictive classification pipeline trained on Kaggle’s *Medical Appointment No Shows* dataset, evaluating patient attendance risk using Logistic Regression and Random Forest models to guide administrative follow-ups.
4. **Data Engineering:** An end-to-end ETL pipeline consolidating multi-branch visit logs, medicine sales, and doctor workloads into actionable executive reports and CSV data marts.
5. **Operating System Concurrency Control:** Multi-threaded simulation contrasting in-memory Mutex locks against database-level ACID transactions to solve race conditions during simultaneous booking attempts.

Deployed on Netlify with Supabase real-time cloud data storage, MedTrack provides a responsive, single-application user experience without mandatory login friction on the public portal while maintaining clinical security.

---

### 2. INTRODUCTION
In expanding metropolitan regions, healthcare providers frequently scale by operating multiple satellite clinics. While this decentralization improves community access, managing patient histories, doctor scheduling, and pharmaceutical inventories independently produces severe operational bottlenecks.

MedTrack bridges the gap between patient accessibility and administrative control. It enables the Head of Hospital (Super Admin) to monitor consolidated KPIs, Branch Heads to supervise their assigned facility, doctors to maintain clinical records, receptionists to register patients, and patients to book appointments and receive emergency rescheduling alerts.

---

### 3. PROBLEM STATEMENT
Traditional clinic management systems suffer from:
1. **Decentralized Data Silos:** Patient health records in one branch are inaccessible when visiting another branch.
2. **Scheduling Conflicts and Race Conditions:** Unprotected booking portals permit two patients to reserve the same doctor slot at the same time.
3. **Emergency Disruption Chaos:** Sudden doctor absence or facility damage requires manual phone calling of dozens of patients, causing delayed care and high no-show rates.
4. **Inventory Leakage:** Lack of real-time multi-branch stock tracking leads to stock-outs of critical antibiotics and expired medicines.
5. **Lack of Predictive Insights:** Clinics cannot anticipate no-show probabilities, leading to idle doctor hours.

---

### 4. EXISTING SYSTEM VS PROPOSED MEDTRACK SYSTEM

| Parameter | Existing Clinic Systems | Proposed MedTrack System |
|---|---|---|
| **Branch Architecture** | Standalone disconnected databases | Unified multi-branch database with RLS isolation |
| **Emergency Handling** | Manual phone calls, high cancellation rate | Automated slot discovery and patient notification engine |
| **Concurrency Safety** | Vulnerable to race conditions / double-bookings | Database partial unique constraints & OS mutex concepts |
| **Predictive Analytics** | None (purely reactive) | Machine learning no-show risk assessment |
| **Inventory Tracking** | Flat sheets, negative quantities permitted | Strict batch lot tracking, non-negative checks, alerts |
| **Real-Time Updates** | Manual browser refresh required | Real-time WebSocket pub/sub via Supabase |
| **Portal Accessibility** | Rigid login walls blocking public browsing | Integrated public homepage with seamless role access |

---

### 5. SYSTEM ARCHITECTURE
MedTrack adopts a decoupled, serverless three-tier architecture:
- **Presentation Tier:** Responsive single-page application built with HTML5, modern CSS3 (Custom Properties & Flexbox/Grid), and Vanilla JavaScript ES6+.
- **Data & Realtime Tier:** Supabase PostgreSQL with Stored Functions (PL/pgSQL), Triggers, Realtime WebSocket Channels, and Row Level Security.
- **Analytics & Data Science Tier:** Python data engineering pipeline and Scikit-Learn machine learning classification pipelines.

---

### 6. CORE MODULES

#### Module 1: Multi-Branch & Role-Based Access Control (RBAC)
Five granular roles:
1. **Super Admin / Head of Hospital:** Global cross-branch monitoring, doctor allocations, system audit logs, and global emergency coordination.
2. **Branch Head:** Isolated management of their branch (Branch A, B, or C).
3. **Doctor:** View assigned appointment queue, access authorized patient medical history, write consultation notes, diagnoses, and issue digital prescriptions.
4. **Receptionist / Staff:** Patient demographic intake, slot booking, rescheduling, and check-in. Receptionists cannot view clinical diagnosis notes.
5. **Patient:** Public hospital exploration, appointment self-service, view digital prescriptions, and receive emergency notification alerts.

#### Module 2: Concurrency-Safe Appointment Management
- Slots validated against doctor weekly working schedules.
- `UNIQUE(doctor_id, appointment_date, appointment_time)` prevents double-booking at the database kernel level.
- Display timings formatted in Indian Standard Time (`Asia/Kolkata`).

#### Module 3: Emergency Management & Auto-Rescheduling Engine
- When an emergency occurs (doctor sudden leave, facility outage), administrators declare an event.
- Stored procedure `declare_hospital_emergency()` finds affected confirmed bookings, marks them `Cancelled - Emergency`, and searches the earliest open slot within 7 days.
- Priority: Same doctor first; alternative doctor in same department and branch second.
- Creates replacement appointment linked via foreign keys to the original.
- Emits in-app patient notifications and records dispatch delivery logs.
- Unfulfillable requests enter a dedicated manual resolution queue for administrator intervention.

#### Module 4: Pharmacy & Medicine Inventory
- Multi-branch catalog tracking batch lot numbers, supplier details, purchase and selling prices, and expiry dates.
- Database constraint `CHECK (quantity_available >= 0)` forbids negative stock.
- Automated warning badges for low stock (`quantity < reorder_level`) and near-expiry medicines.
- Transaction-safe dispensing function `dispense_medicine_sale_safe()` with immutable audit ledger.

#### Module 5: Machine Learning (Patient No-Show Prediction)
- Trained on Kaggle dataset of 110,527 clinical visits.
- Models: Logistic Regression (Medical Interpretability) vs. Random Forest Classifier.
- Evaluated on Accuracy, Precision, Recall, F1-Score, and ROC-AUC.
- Serialized using `joblib` into `ml/models/noshow_model.joblib` for risk scoring.

#### Module 6: Data Engineering Pipeline
- Ingestion, validation, transformation, and analytical report generation.
- Computes branch revenues, doctor workloads, and stock replenishment rosters.
- Generates JSON executive summaries and Markdown operational reports.

#### Module 7: Operating System Concurrency Demonstration
- Python script `os_demo/concurrent_booking.py` demonstrating race conditions, critical sections, and mutual exclusion using `threading.Lock`.
- Connects in-memory OS synchronization with distributed database transactions.

---

### 7. TESTING AND QUALITY VERIFICATION
- Concurrency simulation tested with simultaneous thread execution.
- ML pipeline tested with full dataset preprocessing, model evaluation, and inference.
- Data engineering pipeline tested with ETL extraction, validation assertions, and CSV generation.
- Responsive web UI tested across desktop, tablet, and mobile viewport layouts.

---

### 8. CONCLUSION & FUTURE ENHANCEMENTS
MedTrack demonstrates that academic computer science principles—spanning database normalization, concurrency theory, predictive modeling, and data pipelines—can be integrated into an elegant, production-ready healthcare management application. Future enhancements include telehealth video consultations, HL7/FHIR health data interoperability, and automated SMS gateway integration.
