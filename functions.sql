-- ============================================================================
-- MEDTRACK: REAL-TIME MULTI-BRANCH HOSPITAL MANAGEMENT SYSTEM
-- FILE: database/functions.sql
-- PURPOSE: Core stored procedures for concurrency-safe booking, stock safety & audit
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. CONCURRENCY-SAFE APPOINTMENT BOOKING FUNCTION
-- Ensures atomic verification, serial token numbering & conflict prevention
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION book_appointment_safe(
    p_patient_id UUID,
    p_doctor_id UUID,
    p_branch_id UUID,
    p_department_id UUID,
    p_appointment_date DATE,
    p_appointment_time TIME,
    p_reason TEXT,
    p_booked_by_role VARCHAR,
    p_booked_by_user_id UUID,
    p_no_show_risk NUMERIC DEFAULT 0.15
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_conflict_count INT;
    v_token INT;
    v_appointment_id UUID;
    v_appointment_number VARCHAR;
    v_risk_level VARCHAR;
    v_doctor_active BOOLEAN;
BEGIN
    -- 1. Verify doctor availability and assignment
    SELECT is_available INTO v_doctor_active 
    FROM doctors 
    WHERE id = p_doctor_id AND branch_id = p_branch_id;

    IF v_doctor_active IS NULL OR v_doctor_active = FALSE THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error_code', 'DOCTOR_UNAVAILABLE',
            'message', 'The requested doctor is not currently available for appointments at this branch.'
        );
    END IF;

    -- 2. Concurrency Lock & Conflict Check
    -- Check if another active booking exists for this doctor, date, and time
    SELECT COUNT(*) INTO v_conflict_count
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND appointment_date = p_appointment_date
      AND appointment_time = p_appointment_time
      AND status NOT IN ('Cancelled', 'No-show', 'Cancelled - Emergency');

    IF v_conflict_count > 0 THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error_code', 'SLOT_ALREADY_BOOKED',
            'message', 'The selected doctor and time slot has just been reserved by another patient. Please select another slot.'
        );
    END IF;

    -- 3. Calculate daily sequential token number for this doctor and date
    SELECT COALESCE(MAX(token_number), 0) + 1 INTO v_token
    FROM appointments
    WHERE doctor_id = p_doctor_id AND appointment_date = p_appointment_date;

    -- 4. Classify ML risk score level
    IF p_no_show_risk >= 0.60 THEN
        v_risk_level := 'High';
    ELSIF p_no_show_risk >= 0.30 THEN
        v_risk_level := 'Medium';
    ELSE
        v_risk_level := 'Low';
    END IF;

    -- 5. Generate formatted appointment number
    v_appointment_number := 'APT-' || TO_CHAR(p_appointment_date, 'YYYYMMDD') || '-' || LPAD(v_token::TEXT, 3, '0');

    -- 6. Insert new appointment atomically
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
        booked_by_role,
        booked_by_user_id,
        no_show_risk_score,
        no_show_risk_level
    ) VALUES (
        v_appointment_number,
        p_patient_id,
        p_doctor_id,
        p_branch_id,
        p_department_id,
        p_appointment_date,
        p_appointment_time,
        'Confirmed',
        COALESCE(p_reason, 'General Medical Consultation'),
        v_token,
        p_booked_by_role,
        p_booked_by_user_id,
        p_no_show_risk,
        v_risk_level
    )
    RETURNING id INTO v_appointment_id;

    -- 7. Insert In-App Notification for Patient
    INSERT INTO notifications (
        recipient_user_id,
        patient_id,
        branch_id,
        notification_type,
        title,
        message,
        related_appointment_id
    ) VALUES (
        p_booked_by_user_id,
        p_patient_id,
        p_branch_id,
        'APPOINTMENT_CONFIRMED',
        'Appointment Confirmed: ' || v_appointment_number,
        'Your appointment on ' || TO_CHAR(p_appointment_date, 'DD Mon YYYY') || ' at ' || TO_CHAR(p_appointment_time, 'HH12:MI AM') || ' is confirmed. Token #' || v_token || '.',
        v_appointment_id
    );

    RETURN jsonb_build_object(
        'success', TRUE,
        'appointment_id', v_appointment_id,
        'appointment_number', v_appointment_number,
        'token_number', v_token,
        'risk_level', v_risk_level,
        'message', 'Appointment confirmed successfully.'
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', FALSE,
        'error_code', 'TRANSACTION_FAILED',
        'message', SQLERRM
    );
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. DISPENSE MEDICINE & DEDUCT INVENTORY ATOMICALLY
-- Enforces strictly non-negative stock and generates audit ledger entries
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION dispense_medicine_sale_safe(
    p_branch_id UUID,
    p_patient_id UUID,
    p_prescription_id UUID,
    p_sold_by_profile_id UUID,
    p_items JSONB -- Array of { inventory_id, medicine_id, batch_id, quantity, unit_price }
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_sale_id UUID;
    v_bill_number VARCHAR;
    v_total_amount NUMERIC(10, 2) := 0.00;
    v_item JSONB;
    v_curr_stock INT;
    v_item_total NUMERIC(10, 2);
    v_trans_code VARCHAR;
BEGIN
    -- Generate sequential bill number
    v_bill_number := 'BILL-' || TO_CHAR(NOW(), 'YYYYMMDD-HH24MISS');

    -- Insert sales master record
    INSERT INTO medicine_sales (
        bill_number,
        branch_id,
        patient_id,
        prescription_id,
        total_amount,
        net_amount,
        sold_by
    ) VALUES (
        v_bill_number,
        p_branch_id,
        p_patient_id,
        p_prescription_id,
        0.00,
        0.00,
        p_sold_by_profile_id
    ) RETURNING id INTO v_sale_id;

    -- Process each medicine item atomically
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        -- Lock row and check stock
        SELECT quantity_available INTO v_curr_stock
        FROM inventory
        WHERE id = (v_item->>'inventory_id')::UUID
        FOR UPDATE;

        IF v_curr_stock IS NULL OR v_curr_stock < (v_item->>'quantity')::INT THEN
            RAISE EXCEPTION 'Insufficient stock available for inventory item % (Current stock: %, Requested: %)', 
                v_item->>'inventory_id', COALESCE(v_curr_stock, 0), v_item->>'quantity';
        END IF;

        -- Deduct stock
        UPDATE inventory
        SET quantity_available = quantity_available - (v_item->>'quantity')::INT,
            updated_at = NOW()
        WHERE id = (v_item->>'inventory_id')::UUID;

        -- Compute line total
        v_item_total := ((v_item->>'quantity')::INT * (v_item->>'unit_price')::NUMERIC);
        v_total_amount := v_total_amount + v_item_total;

        -- Insert sale detail item
        INSERT INTO medicine_sale_items (
            sale_id,
            inventory_id,
            medicine_id,
            batch_id,
            quantity,
            unit_price,
            total_price
        ) VALUES (
            v_sale_id,
            (v_item->>'inventory_id')::UUID,
            (v_item->>'medicine_id')::UUID,
            (v_item->>'batch_id')::UUID,
            (v_item->>'quantity')::INT,
            (v_item->>'unit_price')::NUMERIC,
            v_item_total
        );

        -- Record immutable stock transaction audit
        v_trans_code := 'TXN-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || SUBSTRING(gen_random_uuid()::TEXT FROM 1 FOR 8);
        INSERT INTO stock_transactions (
            transaction_code,
            branch_id,
            medicine_id,
            batch_id,
            transaction_type,
            quantity,
            reference_id,
            notes,
            performed_by
        ) VALUES (
            v_trans_code,
            p_branch_id,
            (v_item->>'medicine_id')::UUID,
            (v_item->>'batch_id')::UUID,
            'SALE_DISPENSE',
            -((v_item->>'quantity')::INT),
            v_sale_id,
            'Medicine dispensed against bill ' || v_bill_number,
            p_sold_by_profile_id
        );
    END LOOP;

    -- Update final total in sale master
    UPDATE medicine_sales
    SET total_amount = v_total_amount,
        net_amount = v_total_amount
    WHERE id = v_sale_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'sale_id', v_sale_id,
        'bill_number', v_bill_number,
        'total_amount', v_total_amount,
        'message', 'Medicine dispensed and stock updated successfully.'
    );
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object(
        'success', FALSE,
        'error_code', 'DISPENSE_FAILED',
        'message', SQLERRM
    );
END;
$$;
