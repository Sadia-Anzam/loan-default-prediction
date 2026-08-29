-- 02_transaction_processing.sql
-- Convert transaction-level history into early-life loan behavior.

DROP TABLE IF EXISTS early_transaction_history;

CREATE TABLE early_transaction_history AS
SELECT
    t.loan_id,
    t.transaction_id,
    t.transaction_date,
    t.overdue_amount,
    t.collection_amount,
    t.installment_amount
FROM loan_transaction t
JOIN analytical_loan_scope s
  ON s.loan_id = t.loan_id
WHERE t.transaction_date <=
      s.disbursement_date
      + (s.original_loan_duration * INTERVAL '1 day') / 3;

-- Detect changes in overdue balance.
DROP TABLE IF EXISTS missed_payment_events;

CREATE TABLE missed_payment_events AS
SELECT
    loan_id,
    transaction_id,
    transaction_date,
    overdue_amount,
    overdue_amount
        - COALESCE(
            LAG(overdue_amount) OVER (
                PARTITION BY loan_id
                ORDER BY transaction_id
            ),
            0
          ) AS overdue_change
FROM early_transaction_history;

-- Aggregate missed collection events.
DROP TABLE IF EXISTS early_missed_collection_summary;

CREATE TABLE early_missed_collection_summary AS
SELECT
    loan_id,
    COUNT(*) FILTER (WHERE overdue_change > 0) AS missed_collection_event_count
FROM missed_payment_events
GROUP BY loan_id;
