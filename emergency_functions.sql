-- ============================================================================
-- MEDTRACK: REAL-TIME MULTI-BRANCH HOSPITAL MANAGEMENT SYSTEM
-- FILE: database/emergency_functions.sql
-- PURPOSE: Stored procedures for emergency cancellation, auto-rescheduling & linking
-- ============================================================================

-- ----------------------------------------------------------------------------
-- DECLARE HOSPITAL EMERGENCY AND AUTO-RESCHEDULE AFFECTED APPOINTMENTS
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION declare_hospital_emergency(
    p_branch_id UUID,
    p_doctor_id UUID,          -- NULL if entire department or branch is affected
    p_department_id UUID,      -- NULL if specific to doctor or whole branch
    p_start_date DATE,
    p_end_date DATE,
    p_start_time TIME,
    p_end_time TIME,
    p_severity VARCHAR,
    p_reason TEXT,
    p_reported_by UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_emergency_id UUID;
    v_emergency_code VARCHAR;
    v_affected_count INT := 0;
    v_rescheduled_count INT := 0;
    v_pending_count INT := 0;
    v_appt RECORD;
    v_rep_doctor RECORD;
    v_candidate_date DATE;
    v_candidate_time TIME;
    v_slot_found BOOLEAN;
    v_new_appt_id UUID;
    v_new_appt_number VARCHAR;
    v_new_token INT;
    v_patient_name VARCHAR;
    v_doctor_name VARCHAR;
    v_rep_doctor_name VARCHAR;
    v_branch_name VARCHAR;
    v_dept_name VARCHAR;
    v_notification_msg TEXT;
    v_offset_day INT;
BEGIN
    -- 1. Generate Emergency Identifier
    v_emergency_code := 'EMG-' || TO_CHAR(p_start_date, 'YYYYMMDD') || '-' || SUBSTRING(gen_random_uuid()::TEXT FROM 1 FOR 6);

    -- 2. Insert Emergency Event Record
    INSERT INTO emergency_events (
        event_identifier,
        branch_id,
        department_id,
        doctor_id,
        start_date,
        end_date,
        start_time,
        end_time,
        severity,
        reason,
        reported_by,
        status
    ) VALUES (
        v_emergency_code,
        p_branch_id,
        p_department_id,
        p_doctor_id,
        p_start_date,
        p_end_date,
        COALESCE(p_start_time, '00:00:00'),
        COALESCE(p_end_time, '23:59:59'),
        COALESCE(p_severity, 'High'),
        p_reason,
        p_reported_by,
        'Active'
    ) RETURNING id INTO v_emergency_id;

    -- Fetch branch name for notifications
    SELECT name INTO v_branch_name FROM branches WHERE id = p_branch_id;

    -- 3. Cursor through all affected confirmed appointments
    FOR v_appt IN 
        SELECT a.id, a.appointment_number, a.patient_id, a.doctor_id, a.branch_id, 
               a.department_id, a.appointment_date, a.appointment_time, a.reason_for_visit,
               p.full_name AS patient_name, p.profile_id AS patient_profile_id,
               d.full_name AS doctor_name, dep.name AS department_name
        FROM appointments a
        JOIN patients p ON a.patient_id = p.id
        JOIN doctors d ON a.doctor_id = d.id
        JOIN departments dep ON a.department_id = dep.id
        WHERE a.branch_id = p_branch_id
          AND (p_doctor_id IS NULL OR a.doctor_id = p_doctor_id)
          AND (p_department_id IS NULL OR a.department_id = p_department_id)
          AND a.appointment_date BETWEEN p_start_date AND p_end_date
          AND a.appointment_time BETWEEN COALESCE(p_start_time, '00:00:00') AND COALESCE(p_end_time, '23:59:59')
          AND a.status IN ('Confirmed', 'Pending')
        FOR UPDATE OF a
    LOOP
        v_affected_count := v_affected_count + 1;
        v_slot_found := FALSE;
        v_new_appt_id := NULL;

        -- 4. Search for earliest suitable replacement slot within next 7 days
        -- Priority 1: Same Doctor, same branch (on dates after emergency end_date)
        -- Priority 2: Another Doctor in same department, same branch
        FOR v_offset_day IN 1..7 LOOP
            v_candidate_date := p_end_date + v_offset_day;
            
            -- Skip Sundays (day 0) for clinic operations
            IF EXTRACT(DOW FROM v_candidate_date) = 0 THEN
                CONTINUE;
            END IF;

            -- Check Priority 1: Same Doctor (if doctor is available on candidate date)
            IF p_doctor_id IS NOT NULL THEN
                -- Find valid doctor schedule start times
                FOR v_candidate_time IN 
                    SELECT s.start_time 
                    FROM doctor_schedules s
                    WHERE s.doctor_id = v_appt.doctor_id
                      AND s.day_of_week = EXTRACT(DOW FROM v_candidate_date)
                      AND s.is_active = TRUE
                      AND NOT EXISTS (
                          SELECT 1 FROM appointments ex
                          WHERE ex.doctor_id = v_appt.doctor_id
                            AND ex.appointment_date = v_candidate_date
                            AND ex.appointment_time = s.start_time
                            AND ex.status NOT IN ('Cancelled', 'No-show', 'Cancelled - Emergency')
                      )
                    ORDER BY s.start_time
                    LIMIT 1
                LOOP
                    -- Found replacement with same doctor!
                    v_rep_doctor.id := v_appt.doctor_id;
                    v_rep_doctor.full_name := v_appt.doctor_name;
                    v_slot_found := TRUE;
                    EXIT;
                END LOOP;
            END IF;

            -- If same doctor slot was found, break out of search
            IF v_slot_found THEN
                EXIT;
            END IF;

            -- Priority 2: Alternative qualified doctor in same department and branch
            FOR v_rep_doctor IN 
                SELECT doc.id, doc.full_name, s.start_time
                FROM doctors doc
                JOIN doctor_schedules s ON doc.id = s.doctor_id
                WHERE doc.branch_id = p_branch_id
                  AND doc.department_id = v_appt.department_id
                  AND (p_doctor_id IS NULL OR doc.id <> p_doctor_id)
                  AND doc.is_available = TRUE
                  AND s.day_of_week = EXTRACT(DOW FROM v_candidate_date)
                  AND s.is_active = TRUE
                  AND NOT EXISTS (
                      SELECT 1 FROM appointments ex
                      WHERE ex.doctor_id = doc.id
                        AND ex.appointment_date = v_candidate_date
                        AND ex.appointment_time = s.start_time
                        AND ex.status NOT IN ('Cancelled', 'No-show', 'Cancelled - Emergency')
                  )
                ORDER BY s.start_time
                LIMIT 1
            LOOP
                v_candidate_time := v_rep_doctor.start_time;
                v_slot_found := TRUE;
                EXIT;
            END LOOP;

            IF v_slot_found THEN
                EXIT;
            END IF;
        END LOOP;

        -- 5. Mark original appointment as 'Cancelled - Emergency'
        UPDATE appointments
        SET status = 'Cancelled - Emergency',
            emergency_event_id = v_emergency_id,
            reschedule_reason = p_reason,
            updated_at = NOW()
        WHERE id = v_appt.id;

        -- Record cancellation history
        INSERT INTO appointment_cancellation_history (
            appointment_id,
            cancelled_by,
            cancelled_by_role,
            cancellation_type,
            cancellation_reason,
            replacement_offered
        ) VALUES (
            v_appt.id,
            p_reported_by,
            'hospital_admin',
            'Emergency Cancellation',
            p_reason,
            v_slot_found
        );

        -- 6. If slot found, create replacement appointment linked to original
        IF v_slot_found THEN
            SELECT COALESCE(MAX(token_number), 0) + 1 INTO v_new_token
            FROM appointments
            WHERE doctor_id = v_rep_doctor.id AND appointment_date = v_candidate_date;

            v_new_appt_number := 'APT-' || TO_CHAR(v_candidate_date, 'YYYYMMDD') || '-R' || LPAD(v_new_token::TEXT, 2, '0');

            INSERT INTO appointments (
                appointment_number,
                patient_id,
                doctor_id,
                branch_id,
                department_id,
                appointment_date,
                appointment_time,
                status,
                reason_for_visit,
                token_number,
                original_appointment_id,
                reschedule_reason
            ) VALUES (
                v_new_appt_number,
                v_appt.patient_id,
                v_rep_doctor.id,
                p_branch_id,
                v_appt.department_id,
                v_candidate_date,
                v_candidate_time,
                'Confirmed',
                v_appt.reason_for_visit || ' (Rescheduled from ' || v_appt.appointment_number || ')',
                v_new_token,
                v_appt.id,
                'Auto-rescheduled due to hospital emergency: ' || p_reason
            ) RETURNING id INTO v_new_appt_id;

            -- Link replacement back to original
            UPDATE appointments
            SET replacement_appointment_id = v_new_appt_id
            WHERE id = v_appt.id;

            UPDATE appointment_cancellation_history
            SET replacement_appointment_id = v_new_appt_id
            WHERE appointment_id = v_appt.id;

            v_rescheduled_count := v_rescheduled_count + 1;

            -- Build patient notification message
            v_notification_msg := 'Dear ' || v_appt.patient_name || E',\n\n' ||
                'We regret to inform you that your original appointment (' || v_appt.appointment_number || ') has been cancelled due to an unexpected hospital emergency.\n\n' ||
                'Your replacement appointment has been arranged.\n\n' ||
                'New Appointment Details:\n' ||
                'Hospital Branch: ' || v_branch_name || E'\n' ||
                'Doctor: ' || v_rep_doctor.full_name || E'\n' ||
                'Department: ' || v_appt.department_name || E'\n' ||
                'Original Appointment: ' || TO_CHAR(v_appt.appointment_date, 'DD Mon YYYY') || ' at ' || TO_CHAR(v_appt.appointment_time, 'HH12:MI AM') || E'\n' ||
                'New Appointment: ' || TO_CHAR(v_candidate_date, 'DD Mon YYYY') || ' at ' || TO_CHAR(v_candidate_time, 'HH12:MI AM') || E'\n' ||
                'Token Number: ' || v_new_token || E'\n\n' ||
                'We apologize for the inconvenience.\n\nThank you,\nMedTrack Hospital Management';

            -- In-App Notification
            INSERT INTO notifications (
                recipient_user_id,
                patient_id,
                branch_id,
                notification_type,
                title,
                message,
                related_appointment_id,
                related_emergency_id
            ) VALUES (
                v_appt.patient_profile_id,
                v_appt.patient_id,
                p_branch_id,
                'EMERGENCY_RESCHEDULE',
                'Important: Your MedTrack Appointment Has Been Rescheduled',
                v_notification_msg,
                v_new_appt_id,
                v_emergency_id
            );

            -- Log simulated external notification dispatch (Email / SMS)
            INSERT INTO notification_delivery_logs (
                notification_id,
                channel,
                recipient_address,
                delivery_status,
                provider_response
            ) 
            SELECT n.id, 'EMAIL', 'patient@medtrack.org', 'SIMULATED', 'Patient email notification logged securely.'
            FROM notifications n WHERE n.related_appointment_id = v_new_appt_id
            LIMIT 1;

        ELSE
            -- No slot available: Mark as Awaiting Manual Rescheduling
            UPDATE appointments
            SET status = 'Awaiting Manual Rescheduling'
            WHERE id = v_appt.id;

            v_pending_count := v_pending_count + 1;

            -- Notify Patient of pending reschedule
            INSERT INTO notifications (
                recipient_user_id,
                patient_id,
                branch_id,
                notification_type,
                title,
                message,
                related_appointment_id,
                related_emergency_id
            ) VALUES (
                v_appt.patient_profile_id,
                v_appt.patient_id,
                p_branch_id,
                'EMERGENCY_RESCHEDULE',
                'Emergency Alert: Appointment Cancellation Pending Reschedule',
                'Dear ' || v_appt.patient_name || ', your appointment has been cancelled due to an unexpected emergency (' || p_reason || '). Our administration is currently arranging a replacement slot and will notify you promptly.',
                v_appt.id,
                v_emergency_id
            );
        END IF;

    END LOOP;

    -- Update emergency event counts
    UPDATE emergency_events
    SET affected_appointments_count = v_affected_count,
        rescheduled_count = v_rescheduled_count,
        pending_reschedule_count = v_pending_count
    WHERE id = v_emergency_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'emergency_id', v_emergency_id,
        'emergency_code', v_emergency_code,
        'affected_appointments', v_affected_count,
        'rescheduled_appointments', v_rescheduled_count,
        'pending_manual_rescheduling', v_pending_count,
        'message', 'Emergency declared and automated rescheduling executed successfully.'
    );
END;
$$;
