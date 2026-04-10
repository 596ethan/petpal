# PetPal Execution Rules

## Scope
This AGENTS file applies to the entire workspace at `D:\HongMengprogram\20260317`.

## Product Priority
- Mobile phone experience is the only first-class target for the current stage.
- HarmonyOS phone client in `Cutepetpost` is the primary deliverable.
- Tablet, watch, and multi-device collaboration are out of scope until the phone MVP is complete and accepted.
- `petpal-server` and `petpal-admin` only evolve to support the phone-side MVP.

## Delivery Goal
Build a real, testable phone MVP instead of expanding demo coverage.

Current target chain:
1. Password login
2. View profile
3. View pets
4. View providers and services
5. Create appointment
6. View my appointments
7. Cancel appointment when allowed
8. Admin confirms/completes appointment so phone client reflects real status

## Scope Control
Do first:
- Phone login
- Phone home/community read flow
- Phone pet archive read flow
- Phone provider/service read flow
- Phone appointment create/list/cancel flow
- Backend authentication and appointment persistence
- Admin appointment status operations required by the phone flow

Do not do now:
- Tablet/watch adaptation
- Multi-device collaboration
- Map features
- Search
- Message notifications
- Service reviews
- SMS login
- Third-party login
- Full social interaction completeness
- Any infrastructure work not required by the phone MVP

## Implementation Rules
- Do not keep building on top of `DemoDataStore` for core phone flows.
- Replace mock-backed behavior with real persistence in the exact order required by the phone MVP.
- UI changes must preserve the existing product direction unless a real flow requires change.
- Backend work must be justified by a phone client use case.
- Admin work must be justified by appointment fulfillment or phone-side status visibility.

## Spec Rule
Before each substantive implementation slice, define:
- user goal
- entry screen
- API contract
- success state
- failure state
- test cases

No coding without a concrete slice spec.

## TDD Rule
For every real feature slice:
1. Write failing backend tests first.
2. Implement backend persistence and rules.
3. Write or update phone-side integration/repository tests.
4. Wire the phone UI to real APIs.
5. Verify the full slice manually or through integration tests.

Minimum required test coverage for core slices:
- auth success/failure
- appointment creation
- appointment list by current user
- cancel rules
- admin status transition rules
- phone client error and empty states

## Decision Filter
When choosing what to do next, prefer the option that most directly increases the phone MVP's real usability.
If a task does not improve or unblock the phone MVP, defer it.

## Data Model Rule
Schema and APIs must align with PRD only where needed for the phone MVP.
Do not expand secondary tables early unless the phone flow requires them immediately.

## Completion Standard
A feature is not complete when:
- it only works with mock data
- it only returns request payloads
- it has no state transition tests
- the phone client cannot consume it end-to-end

A feature is complete only when:
- backend behavior is real
- tests cover the business rule
- the phone client consumes the real API
- the end-to-end flow is demonstrable
