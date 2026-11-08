# MedTrack Multi-Branch Hospital: Entity-Relationship (ER) Documentation

## 1. Architectural ER Diagram (Mermaid)

```mermaid
erDiagram
    BRANCHES ||--o{ PROFILES : employs
    BRANCHES ||--o{ DOCTORS : houses
    BRANCHES ||--o{ STAFF : assigns
    BRANCHES ||--o{ PATIENTS : registers
    BRANCHES ||--o{ APPOINTMENTS : hosts
    BRANCHES ||--o{ INVENTORY : maintains
    BRANCHES ||--o{ EMERGENCY_EVENTS : experiences
    
    DEPARTMENTS ||--o{ DOCTORS : categorizes
    DEPARTMENTS ||--o{ STAFF : organizes
    DEPARTMENTS ||--o{ APPOINTMENTS : classifies

    PROFILES ||--o| DOCTORS : authenticates
    PROFILES ||--o| PATIENTS : authenticates
    PROFILES ||--o| STAFF : authenticates
    PROFILES ||--o{ NOTIFICATIONS : receives
    PROFILES ||--o{ AUDIT_LOGS : performs

    PATIENTS ||--o{ APPOINTMENTS : books
    PATIENTS ||--o{ MEDICAL_RECORDS : owns
    PATIENTS ||--o{ CONSULTATIONS : receives
    PATIENTS ||--o{ PRESCRIPTIONS : prescribed
    PATIENTS ||--o{ MEDICINE_SALES : purchases

    DOCTORS ||--o{ DOCTOR_SCHEDULES : provides
    DOCTORS ||--o{ APPOINTMENTS : attends
    DOCTORS ||--o{ CONSULTATIONS : conducts
    DOCTORS ||--o{ PRESCRIPTIONS : issues

    APPOINTMENTS ||--o| CONSULTATIONS : results_in
    APPOINTMENTS ||--o{ APPOINTMENT_CANCELLATION_HISTORY : logged_in
    EMERGENCY_EVENTS ||--o{ APPOINTMENTS : affects

    CONSULTATIONS ||--o| PRESCRIPTIONS : generates
    PRESCRIPTIONS ||--o{ PRESCRIPTION_ITEMS : contains

    MEDICINES ||--o{ PRESCRIPTION_ITEMS : specified_as
    MEDICINES ||--o{ MEDICINE_BATCHES : produced_in
    SUPPLIERS ||--o{ MEDICINE_BATCHES : supplies
    MEDICINE_BATCHES ||--o{ INVENTORY : stocked_as

    INVENTORY ||--o{ MEDICINE_SALE_ITEMS : dispensed_from
    MEDICINE_SALES ||--o{ MEDICINE_SALE_ITEMS : details
    INVENTORY ||--o{ STOCK_TRANSACTIONS : tracked_by
    NOTIFICATIONS ||--o{ NOTIFICATION_DELIVERY_LOGS : tracks_dispatch

    BRANCHES {
        uuid id PK
        varchar code UK
        varchar name
        varchar city
        varchar phone
    }

    PATIENTS {
        uuid id PK
        varchar patient_identifier UK
        varchar full_name
        date date_of_birth
        varchar gender
        varchar phone
        uuid registered_branch_id FK
    }

    DOCTORS {
        uuid id PK
        varchar doctor_identifier UK
        varchar full_name
        uuid department_id FK
        uuid branch_id FK
        varchar specialization
        numeric consultation_fee
    }

    APPOINTMENTS {
        uuid id PK
        varchar appointment_number UK
        uuid patient_id FK
        uuid doctor_id FK
        uuid branch_id FK
        date appointment_date
        time appointment_time
        varchar status
        int token_number
        uuid original_appointment_id FK
        uuid replacement_appointment_id FK
    }

    EMERGENCY_EVENTS {
        uuid id PK
        varchar event_identifier UK
        uuid branch_id FK
        uuid doctor_id FK
        date start_date
        date end_date
        varchar severity
        text reason
    }

    INVENTORY {
        uuid id PK
        uuid branch_id FK
        uuid medicine_id FK
        uuid batch_id FK
        int quantity_available
    }
```

## 2. Cardinality & Relationship Matrix

| Relationship | Entities Involved | Cardinality | Business Logic & Integrity Constraints |
|---|---|---|---|
| **Branch Allocation** | `branches` -> `doctors` | 1 : N | Each doctor belongs to one hospital branch. A branch contains many specialized doctors. |
| **Branch Scheduling** | `doctors` -> `doctor_schedules` | 1 : N | A doctor specifies active consultation slots per weekday. |
| **Clinical Consultation** | `patients` -> `appointments` | 1 : N | A patient can reserve multiple appointments across clinic history. |
| **Concurrency Lock** | `appointments` (`doctor_id`, `date`, `time`) | Unique Constraint | Partial unique index guarantees no overlapping active bookings for the same doctor slot. |
| **Emergency Replacement** | `appointments` -> `appointments` | 1 : 1 (Recursive) | `original_appointment_id` and `replacement_appointment_id` link auto-rescheduled events. |
| **Pharmacy Stock** | `branches` x `medicines` x `batches` -> `inventory` | N : M | Composite uniqueness (`branch_id`, `medicine_id`, `batch_id`) with non-negative stock constraint. |
| **Prescription Items** | `prescriptions` -> `prescription_items` | 1 : N | Each prescription contains one or more medicine dosage lines. |
