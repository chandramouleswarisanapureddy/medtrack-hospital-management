"""
=============================================================================
MEDTRACK: OPERATING SYSTEM CONCEPTS MODULE
FILE: os_demo/concurrent_booking.py
PURPOSE: Multi-threaded demonstration of Race Conditions & Mutual Exclusion
=============================================================================
Academic Concepts Illustrated:
1. Thread vs Process
2. Race Condition: Unsynchronized concurrent modification of shared resource
3. Critical Section: Code block that accesses shared appointment slot table
4. Mutual Exclusion (Mutex): Lock acquisition ensuring serialized execution
5. Semaphore: Generalized signaling mechanism for resource allocation
6. OS Concurrency vs Database ACID Transactions
=============================================================================
"""

import time
import threading
from dataclasses import dataclass, field
from typing import Dict, List, Optional

@dataclass
class AppointmentSlot:
    doctor_id: str
    doctor_name: str
    date: str
    time: str
    booked_by: Optional[str] = None
    is_booked: bool = False
    booking_history: List[str] = field(default_factory=list)

# ----------------------------------------------------------------------------
# 1. UNSYNCHRONIZED SYSTEM (RACE CONDITION DEMONSTRATION)
# ----------------------------------------------------------------------------
class UnsafeBookingSystem:
    def __init__(self):
        self.slot = AppointmentSlot(
            doctor_id="MED-DOC-001",
            doctor_name="Dr. Rajesh Sharma",
            date="2026-11-09",
            time="10:00 AM"
        )
        self.successful_bookings = []
        self.failed_bookings = []

    def attempt_booking(self, patient_name: str):
        """
        Simulates unsynchronized slot booking with artificial context switch delay.
        """
        # CRITICAL SECTION ENTRY (UNPROTECTED)
        # Check if slot is available
        if not self.slot.is_booked:
            # Simulate OS thread context switch / I/O latency
            time.sleep(0.01)
            
            # State update (Unprotected write to shared memory)
            self.slot.is_booked = True
            self.slot.booked_by = patient_name
            self.slot.booking_history.append(patient_name)
            self.successful_bookings.append(patient_name)
            # CRITICAL SECTION EXIT
        else:
            self.failed_bookings.append(patient_name)

# ----------------------------------------------------------------------------
# 2. SYNCHRONIZED SYSTEM (MUTEX / LOCK PROTECTION)
# ----------------------------------------------------------------------------
class SafeBookingSystem:
    def __init__(self):
        self.slot = AppointmentSlot(
            doctor_id="MED-DOC-001",
            doctor_name="Dr. Rajesh Sharma",
            date="2026-11-09",
            time="10:00 AM"
        )
        # Operating System Mutex (Mutual Exclusion Lock)
        self.mutex = threading.Lock()
        self.successful_bookings = []
        self.failed_bookings = []

    def attempt_booking(self, patient_name: str):
        """
        Synchronized slot booking using a Mutex Lock.
        """
        # ACQUIRE MUTEX LOCK -> Enforces Mutual Exclusion
        with self.mutex:
            # CRITICAL SECTION START
            if not self.slot.is_booked:
                # Even if preemption occurs, other threads are blocked waiting for mutex
                time.sleep(0.01)
                
                self.slot.is_booked = True
                self.slot.booked_by = patient_name
                self.slot.booking_history.append(patient_name)
                self.successful_bookings.append(patient_name)
                # CRITICAL SECTION END
            else:
                self.failed_bookings.append(patient_name)
        # MUTEX AUTOMATICALLY RELEASED

# ----------------------------------------------------------------------------
# 3. CONCURRENCY BENCHMARK RUNNER
# ----------------------------------------------------------------------------
def run_simulation():
    print("=" * 75)
    print("MEDTRACK OS CONCURRENCY DEMONSTRATION")
    print("SCENARIO: 2 PATIENTS SIMULTANEOUSLY BOOKING DR. SHARMA (10:00 AM SLOT)")
    print("=" * 75)

    # ------------------------------------------------------------------------
    # EXPERIMENT 1: UNSAFE (WITHOUT MUTEX)
    # ------------------------------------------------------------------------
    print("\n[TEST 1] Executing Unsynchronized Booking (No Concurrency Control)...")
    unsafe_sys = UnsafeBookingSystem()

    t1 = threading.Thread(target=unsafe_sys.attempt_booking, args=("Patient A (Rahul Verma)",))
    t2 = threading.Thread(target=unsafe_sys.attempt_booking, args=("Patient B (Deepa Shankar)",))

    # Launch threads concurrently
    t1.start()
    t2.start()

    # Wait for completion
    t1.join()
    t2.join()

    print(f"  -> Total booking confirmations granted : {len(unsafe_sys.successful_bookings)}")
    print(f"  -> Patients confirmed                 : {unsafe_sys.successful_bookings}")
    print(f"  -> Slot Final Holder                   : {unsafe_sys.slot.booked_by}")
    
    if len(unsafe_sys.successful_bookings) > 1:
        print("  [!] CRITICAL ANOMALY: RACE CONDITION OCCURRED!")
        print("      Both patients received a confirmation for the exact same slot!")
        print("      Operating System Cause: Thread context switch occurred inside the")
        print("      unprotected critical section before shared memory was updated.")
    else:
        print("  -> Race condition did not manifest on this iteration.")

    # ------------------------------------------------------------------------
    # EXPERIMENT 2: SAFE (WITH MUTEX LOCK)
    # ------------------------------------------------------------------------
    print("\n[TEST 2] Executing Mutex-Synchronized Booking (Mutual Exclusion Enforced)...")
    safe_sys = SafeBookingSystem()

    t3 = threading.Thread(target=safe_sys.attempt_booking, args=("Patient A (Rahul Verma)",))
    t4 = threading.Thread(target=safe_sys.attempt_booking, args=("Patient B (Deepa Shankar)",))

    t3.start()
    t4.start()

    t3.join()
    t4.join()

    print(f"  -> Total booking confirmations granted : {len(safe_sys.successful_bookings)}")
    print(f"  -> Successful patient confirmation     : {safe_sys.successful_bookings}")
    print(f"  -> Rejected / Conflicted attempts      : {safe_sys.failed_bookings}")
    print(f"  -> Slot Assigned Exclusively To        : {safe_sys.slot.booked_by}")
    print("  [+] SUCCESS: MUTUAL EXCLUSION PRESERVED!")
    print("      Only 1 patient secured the slot; second patient safely received an")
    print("      'Already Reserved' notification without data corruption.")

    # ------------------------------------------------------------------------
    # ARCHITECTURAL COMPARISON: OS MUTEX VS POSTGRESQL ACID TRANSACTIONS
    # ------------------------------------------------------------------------
    print("\n" + "=" * 75)
    print("ACADEMIC COMPARISON: OS MUTEX VS DATABASE-LEVEL CONCURRENCY")
    print("=" * 75)
    print("""
1. OS Level (threading.Lock / Semaphore):
   - Scope: Single OS process and shared virtual memory address space.
   - Limitation: In modern distributed web apps (like Netlify + Supabase),
     multiple web servers or Edge function runtimes execute on distinct
     machines. An in-memory Python mutex CANNOT synchronize across physical servers.

2. Database Level (MedTrack PostgreSQL Implementation):
   - Concurrency Mechanism 1: Partial Unique Constraint:
     CREATE UNIQUE INDEX idx_unique_active_doctor_slot 
     ON appointments(doctor_id, appointment_date, appointment_time)
     WHERE status NOT IN ('Cancelled', 'No-show', 'Cancelled - Emergency');
     
   - Concurrency Mechanism 2: Pessimistic Row Locking:
     SELECT quantity_available FROM inventory WHERE id = ... FOR UPDATE;
     
   - Guarantee: Full ACID serializability across all distributed web clients.
    """)
    print("=" * 75 + "\n")

if __name__ == "__main__":
    run_simulation()
