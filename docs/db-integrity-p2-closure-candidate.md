# DB Integrity P2 Closure Candidate

## Status

Review date: 2026-05-06

Current state: closure candidate only. This is not sealed.

P0, P1, and P2a-P2g have been completed and applied to the live local MySQL `petpal` database.

## Confirmed State

- P0/P1/P2a-P2f DDL constraints are present in live MySQL.
- P2g repaired stored post derived-count drift without adding new DDL.
- `post_derived_count_drift = 0`.
- `schema.sql`, the live MySQL constraints, the maintenance scripts, and the acceptance records are currently aligned for P0/P1/P2a-P2g.
- `scripts/db-integrity-p2-summary-readonly.sql` reports all 42 expected P0/P1/P2a-P2f DDL constraints as `present`.
- `service_review` candidate checks currently return `0` for appointment orphans, user orphans, provider orphans, and rating out-of-range rows.
- `.\scripts\test-backend.ps1` passed with `Tests run: 63, Failures: 0, Errors: 0, Skipped: 0`.

## Not Sealed

This is not a sealed P2 record because several candidates are intentionally moved out of the current database plan and into backlog.

Backlog items:

- `service_review` foreign keys and rating CHECK constraints.
- `user.status`, `post.status`, and `service_provider.status` CHECK constraints.
- Automatic `updated_at` maintenance.
- A formal migration mechanism such as Flyway or Liquibase.

## References

- Summary review: `docs/db-integrity-p2-summary-review.md`
- Read-only summary SQL: `scripts/db-integrity-p2-summary-readonly.sql`
- P2g acceptance record: `docs/db-integrity-p2g-derived-counts-acceptance.md`
