# ACE BDD feature files

Illustrative Gherkin scenarios for ACE (AI for Cooling Efficiency). Use for specification-by-example, acceptance criteria, and as a backlog for automation.

| Feature file | Scope | Tags |
|--------------|--------|------|
| **guardian_validate.feature** | Guardian API – validation rules, boundaries, invalid request. *Implemented* as Python/C# API tests. | `@guardian` `@api` |
| **ace_api.feature** | ACE API: Guardian validate contract/errors/HTTP, health, config, auth, performance, Optimiser/Digital Twin when present. | `@ace_api` `@guardian` `@health` `@config` `@security` `@performance` |
| **ace_components.feature** | ACE key components: Optimiser, Digital Twin, Guardian, Advisor; end-to-end flows. | `@optimiser` `@digital_twin` `@guardian` `@advisor` `@e2e` |
| **ace_ui.feature** | User interface: login, Home, Cooling Management, One-Click Approval, Advisor, reporting. | `@ui` `@facility_manager` |
| **ace_non_functional.feature** | Non-functional: API performance, security (TLS, auth, data privacy), reliability, error handling, deployment, UI performance. | `@performance` `@security` `@reliability` `@deployment` |

**Running automated tests:** Only `guardian_validate.feature` is currently automated (see `tests/test_guardian_validate.py` and C# `GuardianValidateTests`). The other features are specifications; implement step definitions and hooks as needed (e.g. Playwright for UI, API clients for Optimiser/Digital Twin).

**Parameterised timeout:** Scenarios that reference `"<timeout>"` can be filled from env (e.g. `TIMEOUT` in `.env`) when implementing.
