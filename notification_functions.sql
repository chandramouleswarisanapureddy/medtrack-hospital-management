-- ============================================================================
-- MEDTRACK: REAL-TIME MULTI-BRANCH HOSPITAL MANAGEMENT SYSTEM
-- FILE: database/notification_functions.sql
-- PURPOSE: In-app notification management, unread counts & delivery auditing
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. MARK NOTIFICATION AS READ
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION mark_notification_read(p_notification_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE notifications
    SET is_read = TRUE,
        read_at = NOW()
    WHERE id = p_notification_id;

    RETURN FOUND;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. GET UNREAD NOTIFICATION COUNT
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INT
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT COUNT(*)::INT
    FROM notifications
    WHERE recipient_user_id = p_user_id
      AND is_read = FALSE;
$$;

-- ----------------------------------------------------------------------------
-- 3. LOG NOTIFICATION DELIVERY
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION log_notification_delivery(
    p_notification_id UUID,
    p_channel VARCHAR,
    p_recipient_address VARCHAR,
    p_status VARCHAR,
    p_provider_response TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO notification_delivery_logs (
        notification_id,
        channel,
        recipient_address,
        delivery_status,
        provider_response
    ) VALUES (
        p_notification_id,
        p_channel,
        p_recipient_address,
        p_status,
        p_provider_response
    ) RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$;
