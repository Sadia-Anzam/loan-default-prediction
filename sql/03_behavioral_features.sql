-- 03_behavioral_features.sql
-- Build loan-level behavioral predictors from early-life history.

DROP TABLE IF EXISTS early_behavior_features;

CREATE TABLE early_behavior_features AS
WITH transaction_features AS (
    SELECT
        h.loan_id,
        MAX(h.overdue_amount) AS max_overdue_amount,
        MAX(
            CASE
                WHEN h.overdue_amount > 0 THEN
                    EXTRACT(
                        DAY FROM (
                            h.transaction_date
                            - MIN(h.transaction_date) OVER (PARTITION BY h.loan_id)
                        )
                    )
                ELSE 0
            END
        ) AS max_overdue_persistence_days,
        SUM(CASE WHEN h.overdue_amount > 0 THEN 1 ELSE 0 END)
            AS overdue_observation_count,
        SUM(h.collection_amount) AS total_collection_amount,
        SUM(h.overdue_amount) AS total_overdue_amount
    FROM early_transaction_history h
    GROUP BY h.loan_id
)
SELECT
    s.loan_id,
    s.frequency_id,
    s.original_installment_count,
    s.installment_amount,
    s.disbursed_amount,

    COALESCE(m.missed_collection_event_count, 0)
        AS missed_collection_event_count,

    COALESCE(f.max_overdue_amount, 0)
        AS max_overdue_amount,

    COALESCE(f.max_overdue_persistence_days, 0)
        AS max_overdue_persistence_days,

    COALESCE(f.overdue_observation_count, 0)
        AS overdue_observation_count,

    COALESCE(f.total_collection_amount, 0)
        AS total_collection_amount,

    COALESCE(f.total_overdue_amount, 0)
        AS total_overdue_amount,

    -- Frequency-normalized overdue duration.
    COALESCE(f.max_overdue_persistence_days, 0)
        / NULLIF(scheduled_frequency_days(s.frequency_id), 0)
        AS pass_due_cycle_ratio,

    -- Relative overdue burden.
    COALESCE(f.total_overdue_amount, 0)
        / NULLIF(
            s.original_installment_count * s.installment_amount,
            0
        )
        AS overdue_proportion

FROM analytical_loan_scope s
LEFT JOIN early_missed_collection_summary m
    ON m.loan_id = s.loan_id
LEFT JOIN transaction_features f
    ON f.loan_id = s.loan_id;
