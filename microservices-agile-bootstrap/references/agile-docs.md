# Scrum product documents: expected structure

Write in English, concisely, focused on decisions. An agile document nobody rereads is useless: prefer tables and short lists.

## Contents
- vision.md
- roadmap.md
- product-backlog.md
- sprint-0.md
- sprint-1-planning.md
- risks.md
- Sample user story

---

## docs/product/vision.md

```
# Product vision — <Title>
## Vision statement        (1 sentence: For <target> who <need>, <product> is a <category> that <benefit>. Unlike <alternative>, our product <differentiator>.)
## Context and problem     (3–5 lines)
## Personas                (table: persona | goal | current frustration)
## Goals and indicators    (table: goal | measurable KPI | target | deadline)
## Scope                   (Included / Out of scope for v1)
## Constraints and assumptions
## Stakeholders            (role | name or "to be defined" | expectation)
```

## docs/product/roadmap.md

Releases by value, not by technical component. 3 to 4 milestones, each with a goal, targeted epics, MoSCoW priority (Must/Should/Could/Won't) and exit criterion. Remind readers that the roadmap is a plan of intent, reviewed at every sprint review.

## docs/product/product-backlog.md

Structure:
1. **Conventions**: identifiers `EP-01` (epic) / `US-001` (story), estimates in story points (Fibonacci 1-2-3-5-8-13), MoSCoW priority, status (To do / Ready / In progress / Done). A story over 8 points is split.
2. **Summary table**: id | title | epic | priority | points | status | service(s) involved
3. **Details by epic**: goal, then each story in the format below.
4. **Technical (enablement) stories**: traceability of foundations (CI, observability, security). Phrase them with a value ("so that we can deploy without regressions"), not as tasks.

Story quality criteria (INVEST): Independent, Negotiable, Valuable, Estimable, Small, Testable.

## Sample user story

```
### US-004 — Place an order
**As a** signed-in customer **I want** to confirm my cart **so that** I receive my items.
- Epic: EP-02 Ordering · Priority: Must · Estimate: 5 · Service(s): order, notification
- Acceptance criteria:
  - Given a non-empty cart, when I confirm, then an order with status CREATED is saved and its identifier is returned to me.
  - Given a created order, then an `order.events` event is published and a notification is recorded.
  - Given an empty cart, when I confirm, then I receive an explicit 400 error.
- Technical notes: publish after commit; no synchronous call to notification.
- Dependencies: US-002
```

## docs/sprints/sprint-0.md

Goal: "A deployable end-to-end increment exists". Table of what the skeleton already provides (check ✅: parent POM, config/discovery/gateway, services with REST+JPA+Kafka, Angular front, docker-compose, ELK, K8s manifests, CI, Keycloak authentication and roles) and what remains (⬜: data ownership, Keycloak hardening, environments, datasets, deployment pipeline). End with the Sprint 0 Definition of Done and the end date.

## docs/sprints/sprint-1-planning.md

- Duration (2 weeks by default), dates, team capacity (to fill in: number of people × days)
- **Sprint goal**: one sentence focused on user value (e.g. "A customer can create an order and see its confirmation")
- **Sprint backlog**: 4 to 6 stories from the top of the backlog, meeting the Definition of Ready (see `docs/agile/definition-of-ready.md`), total points ≤ assumed velocity (if unknown, 20–25 for a small team, to adjust after the sprint)
- Task breakdown per story (optional but useful)
- Known sprint risks and dependencies
- Event reminders: daily, review, retrospective (dates)

## docs/product/risks.md

Table: id | risk | probability (L/M/H) | impact (L/M/H) | mitigation | owner | status. Include at least: operational complexity of microservices for a small team, eventual data consistency across services, memory use of the ELK/Kafka stack locally, access to other users' data (the skeleton enforces roles but not data ownership) and Keycloak in dev mode, version dependencies (Angular 15 out of LTS support).
