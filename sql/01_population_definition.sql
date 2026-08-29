-- 01_population_definition.sql
-- Define the analytical loan population and the early observation point.

DROP TABLE IF EXISTS analytical_loan_scope;

CREATE TABLE analytical_loan_scope AS
SELECT
    l.loan_id,
    l.borrower_id,
    l.product_id,
    l.project_id,
    l.sector_id,
    l.frequency_id,
    l.disbursement_date,
    l.original_loan_duration,
    l.original_installment_count,
    l.disbursed_amount,
    l.installment_amount,
    l.interest_rate,
    l.current_installment_no
FROM loan_master l
WHERE l.disbursement_date >= DATE '2022-01-01'
  AND l.active_flag = 1
  AND l.frequency_id <> <excluded_frequency>
  AND l.special_portfolio_flag = 0
  AND l.current_installment_no >= ROUND(l.original_installment_count / 3.0);

-- Keep one observation around the one-third lifecycle boundary.
DROP TABLE IF EXISTS early_lifecycle_snapshot;

CREATE TABLE early_lifecycle_snapshot AS
SELECT
    s.loan_id,
    t.transaction_date,
    t.overdue_amount,
    t.collection_amount,
    t.outstanding_balance
FROM analytical_loan_scope s
JOIN loan_transaction t
  ON t.loan_id = s.loan_id
WHERE t.transaction_date <=
      s.disbursement_date
      + (s.original_loan_duration * INTERVAL '1 day') / 3
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY s.loan_id
    ORDER BY t.transaction_date DESC, t.transaction_id DESC
) = 1;
