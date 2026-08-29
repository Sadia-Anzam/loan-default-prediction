# SQL — Analytical Dataset Construction

The production project started from multiple transactional sources and transformed them
into a loan-level analytical dataset for early-default prediction.

The public SQL is intentionally abstracted:

- production database names are removed;
- production table names are replaced with generic names;
- production column names are generalized;
- internal identifiers and business-specific codes are omitted;
- credentials and environment-specific details are excluded.

The structure mirrors the analytical logic rather than the proprietary implementation.

## Pipeline

```text
Source loan data
      ↓
Eligible loan population
      ↓
Early-life observation boundary
      ↓
Transaction-level aggregation
      ↓
Behavioral features
      ↓
Quality / exclusion rules
      ↓
Loan-level analytical dataset
```

## Files

- `01_population_definition.sql`
- `02_transaction_processing.sql`
- `03_behavioral_features.sql`
- `04_data_quality_and_exclusions.sql`

These scripts are representative public examples. They are not executable against the
production database without adapting the generic source names and fields to a public schema.
