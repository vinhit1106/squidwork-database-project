# Phase 1 Requirements Review

**Reviewer:** Le Minh Thien  
**Scope:** Requirements and business rules for the SquidWork conceptual design

## Review notes

The project scope is limited to the core freelance marketplace flow: clients post jobs, freelancers submit proposals, an accepted proposal becomes a contract, and contract work is divided into milestones. Reviews are included because trust and reputation are part of the marketplace scenario.

The requirements are appropriate for Phase 1 because they describe what information the database must support without assuming a specific SQL implementation. The later phases can map these requirements to relations, constraints, queries, and application screens.

## Rules checked

| Rule | Review result |
|---|---|
| A user may act as a client, a freelancer, or both. | Correct. The two profiles must be optional and overlapping rather than mutually exclusive. |
| A client can post many jobs and each job belongs to one client. | Correct. This is the main ownership relationship in the scenario. |
| A freelancer can submit at most one proposal for a specific job. | Correct. This prevents duplicate offers from the same freelancer for one job. |
| An accepted proposal may create at most one contract. | Correct. The rule connects the proposal stage to the contract stage. |
| A reviewer cannot review the same reviewee twice for the same contract. | Correct. This avoids duplicate feedback for one completed engagement. |

## Phase 1 conclusion

The requirements and business rules are consistent with the chosen project topic and provide enough detail for the EER model. No change to the Phase 1 scope is required.
