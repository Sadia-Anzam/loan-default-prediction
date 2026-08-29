-- 04_data_quality_and_exclusions.sql
-- Remove records that are outside the analytical scope or not reliable enough to use.

DROP TABLE IF EXISTS excluded_loans;

CREATE TABLE excluded_loans AS
SELECT DISTINCT loan_id
FROM analytical_loan_scope
WHERE 1 = 0;

-- Example: operationally invalid / out-of-scope populations.
INSERT INTO excluded_loans
SELECT DISTINCT loan_id
FROM loan_operational_events
WHERE event_type IN (
    'member_deceased',
    'incident_during_loan',
    'administrative_exclusion'
);

-- Example: loans whose product/rate configuration is outside the study scope.
INSERT INTO excluded_loans
SELECT DISTINCT loan_id
FROM analytical_loan_scope
WHERE interest_rate = 0;

-- Remove excluded loans from the final analytical population.
DROP TABLE IF EXISTS modeling_population;

CREATE TABLE modeling_population AS
SELECT
    b.*
FROM early_behavior_features b
LEFT JOIN excluded_loans e
    ON e.loan_id = b.loan_id
WHERE e.loan_id IS NULL;

-- Quality checks.
SELECT COUNT(*) AS modeling_rows
FROM modeling_population;

SELECT
    COUNT(*) FILTER (WHERE loan_id IS NULL) AS missing_loan_id,
    COUNT(*) FILTER (WHERE installment_amount <= 0) AS invalid_installment_amount
FROM modeling_population;
