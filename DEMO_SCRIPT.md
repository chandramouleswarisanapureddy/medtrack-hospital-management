# MedTrack: Academic Project Demonstration Script

This script guides you through a confident 10-minute presentation and live viva demonstration.

---

### Phase 1: Introduction & Architecture (2 Minutes)
1. **Open the Website:**
   - Open `index.html` (or deployed Netlify link `https://luminous-starburst-5ce75d.netlify.app`).
   - Highlight:
     > *"Respected Examiners, MedTrack is an integrated, real-time multi-branch hospital management system. Notice that the homepage opens directly without forcing a mandatory login screen, welcoming patients with hospital services, doctor specialties, and branch information across our 3 branches: Branch A (Metro Central), Branch B (Tech City), and Branch C (Green Valley)."*
2. **Explain the Tech Stack:**
   - Frontend: Responsive HTML5, CSS3, Vanilla JavaScript.
   - Backend & Database: Supabase PostgreSQL, Stored Functions, RLS, and Realtime pub/sub.
   - Data Science: Machine Learning No-Show Prediction and Python Data Engineering Pipeline.

---

### Phase 2: Role-Based Dashboards & Patient Booking (3 Minutes)
1. **Public Booking:**
   - Scroll to the **Book Appointment** section on the homepage or click **Appointments**.
   - Select **Branch A (Metro Central)** -> Department **Cardiology** -> Doctor **Dr. Rajesh Sharma**.
   - Show available time slots (e.g. 10:00 AM) and explain that duplicate bookings are prevented by PostgreSQL partial unique constraints.
2. **Role Switcher Demonstration:**
   - In the top navigation bar, use the **Active Role** dropdown:
     - **Super Admin (Dr. Arvind Swaminathan):** Show consolidated KPI cards for all 3 branches, global occupancy, total revenue, and system audit logs.
     - **Branch Head A (Dr. Ramesh Kulkarni):** Notice the dashboard strictly isolates metrics to Branch A only.
     - **Doctor (Dr. Rajesh Sharma):** View assigned patient appointments, clinical consultation notes, and branch medicine inventory.
     - **Receptionist (Kavita Menon):** Patient check-in and booking queue without access to confidential doctor clinical notes.
     - **Patient (Rahul Verma):** Personal appointment history, digital prescriptions, and notification center.

---

### Phase 3: The Special Feature – Emergency Cancellation & Auto-Rescheduling (3 Minutes)
1. **Navigate to Emergency Management:**
   - Switch role to **Super Admin** or **Branch Head A**. Click **Emergency Center** in navigation (`emergency.html`).
2. **Report a Hospital Emergency:**
   - Click **Report Hospital Emergency**.
   - Select:
     - **Branch:** MedTrack Metro Central (Branch A)
     - **Doctor:** Dr. Rajesh Sharma (Cardiology)
     - **Emergency Date:** Select today or tomorrow's clinic date
     - **Time Range:** 09:00 AM to 01:00 PM
     - **Reason:** *"Doctor called for urgent emergency cardiac surgery at regional trauma center"*
   - Click **Confirm & Trigger Emergency Rescheduling**.
3. **Show Real-Time Results:**
   - Show how the system instantly:
     1. Identifies affected confirmed appointments.
     2. Marks original appointments as `Cancelled - Emergency` with audit logging.
     3. Automatically discovers the earliest open replacement slot (preferring the same doctor or a backup cardiologist like Dr. Sandeep Hegde in Branch A).
     4. Generates linked replacement appointments.
     5. Emits In-App Patient Notifications.
4. **Inspect Patient Notification:**
   - Switch role to **Patient (Rahul Verma)**.
   - Point to the **Notification Bell** with the new unread badge.
   - Open notifications to display the detailed reschedule message with the old vs new appointment date, doctor, branch, and token.

---

### Phase 4: Machine Learning, Data Engineering & OS Concurrency (2 Minutes)
1. **Machine Learning Module:**
   - Show `ml/train_model.py` and run:
     ```bash
     python ml/predict.py --age 52 --lead_days 14 --sms 1
     ```
   - Explain how Logistic Regression and Random Forest models evaluate no-show probability to optimize reminder workflows.
2. **Data Engineering ETL Pipeline:**
   - Run:
     ```bash
     python data_engineering/generate_reports.py
     ```
   - Show the generated analytical reports in `data_engineering/output/executive_report.md` summarizing multi-branch revenue and pharmacy stock replenishment.
3. **Operating System Concurrency Demo:**
   - Run:
     ```bash
     python os_demo/concurrent_booking.py
     ```
   - Explain the live demonstration of race conditions when unprotected vs safe mutual exclusion via mutex lock.
