# MedTrack: Quality Assurance & Testing Checklist

## 1. Test Summary Matrix

| Module | Test Case ID | Test Objective | Test Strategy | Status |
|---|---|---|---|---|
| **DBMS** | TC-DB-01 | Normalized table creation & constraints | Run `database/schema.sql` on PostgreSQL | Verified |
| **DBMS** | TC-DB-02 | Seed data insertion across 3 branches | Run `database/seed.sql` | Verified |
| **DBMS** | TC-DB-03 | Prevention of negative inventory stock | Check constraint `quantity_available >= 0` | Verified |
| **Concurrency**| TC-OS-01 | Unprotected concurrent booking race condition | Execute `os_demo/concurrent_booking.py` (Test 1) | Verified (Race manifested) |
| **Concurrency**| TC-OS-02 | Mutex-synchronized booking mutual exclusion | Execute `os_demo/concurrent_booking.py` (Test 2) | Verified (Only 1 booked) |
| **Concurrency**| TC-DB-04 | Database partial unique index on slot | `idx_unique_active_doctor_slot` prevents duplicate insert | Verified |
| **Emergency** | TC-EMG-01 | Emergency reporting & batch cancellation | Run `declare_hospital_emergency()` | Verified |
| **Emergency** | TC-EMG-02 | Automatic replacement slot search (Same Doc) | Priority 1 search across valid clinic dates | Verified |
| **Emergency** | TC-EMG-03 | Automatic replacement slot search (Same Dept) | Priority 2 search across alternate qualified doctors | Verified |
| **Emergency** | TC-EMG-04 | Unreschedulable appointments to manual queue | Fallback status `'Awaiting Manual Rescheduling'` | Verified |
| **Emergency** | TC-EMG-05 | In-App notification & delivery log generation | Notification insert with unread bell counter | Verified |
| **ML Module** | TC-ML-01 | Kaggle dataset ingestion & preprocessing | Execute `ml/train_model.py` | Verified |
| **ML Module** | TC-ML-02 | Model training & evaluation (LR & RF) | Metrics generated (Acc, Prec, Rec, F1, ROC) | Verified |
| **ML Module** | TC-ML-03 | CLI & API prediction output | Execute `ml/predict.py --age 52 --lead_days 14` | Verified |
| **Data Eng.** | TC-DE-01 | Multi-branch operational ETL pipeline | Execute `data_engineering/pipeline.py` | Verified |
| **Data Eng.** | TC-DE-02 | Executive report generation (JSON & Markdown) | Execute `data_engineering/generate_reports.py` | Verified |
| **Frontend** | TC-UI-01 | Public homepage loads directly (No login wall) | Open `index.html` in browser | Verified |
| **Frontend** | TC-UI-02 | Responsive layout on desktop & mobile | Viewport testing from 375px to 1440px | Verified |
| **Frontend** | TC-UI-03 | Role switcher for academic live evaluation | Switch between Super Admin, Branch Head, Doctor, Receptionist, Patient | Verified |
| **Frontend** | TC-UI-04 | In-app notification bell with unread badge | Bell click opens notification drawer | Verified |
