# Phase 1 Relationship and Cardinality Review

**Reviewer:** Nguyen Tuan Vy  
**Scope:** EER relationships and cardinalities for the SquidWork conceptual design

## Relationship checks

| Relationship | Cardinality | Review result |
|---|---|---|
| USER - CLIENT_PROFILE | 1 to 0..1 | Correct. A registered user may not act as a client, or may have one client profile. |s
| USER - FREELANCER_PROFILE | 1 to 0..1 | Correct. A registered user may not act as a freelancer, or may have one freelancer profile. |
| CLIENT_PROFILE - JOB | 1 to N | Correct. One client can post many jobs, while each job has one owning client. |
| JOB_CATEGORY - JOB | 1 to N | Correct. Each job has one category, and a category can contain many jobs. |
| JOB - PROPOSAL | 1 to N | Correct. A job can receive multiple proposals, with each proposal belonging to one job. |
| PROPOSAL - CONTRACT | 1 to 0..1 | Correct. A proposal creates no contract unless accepted, and cannot create multiple contracts. |
| CONTRACT - MILESTONE | 1 to N | Correct. A contract is delivered through one or more ordered milestones. |
| MILESTONE - PAYMENT | 1 to 0..1 | Correct. A milestone may exist before payment and may have at most one payment. |
| CONTRACT - REVIEW | 1 to N | Correct. The parties can leave feedback after the contract is completed. |

## EER specialization check

`USER` is the supertype. `CLIENT_PROFILE` and `FREELANCER_PROFILE` are overlapping subtypes because the same user may have both roles. The freelancer-skill many-to-many relationship is represented conceptually by `FREELANCER_SKILL`, which will be mapped to an associative relation in Phase 2.

## Phase 1 conclusion

The documented relationships and cardinalities match the business rules. The model is ready for the Phase 2 relational mapping step.
## Additional review note

I reviewed the relationship descriptions against the Phase 1 EER overview. The cardinalities are consistent with the business rules: one client can post many jobs, one job can receive many proposals, and an accepted proposal can create at most one contract. The USER specialization is overlapping because one account may have both a client profile and a freelancer profile.
