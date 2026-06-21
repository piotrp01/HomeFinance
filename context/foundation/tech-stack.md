---
starter_id: dotnet
package_manager: dotnet
project_name: home-finance
hints:
  language_family: dotnet
  team_size: solo
  deployment_target: azure-app-service
  ci_provider: github-actions
  ci_default_flow: auto-deploy-on-merge
  bootstrapper_confidence: verified
  path_taken: standard
  quality_override: false
  self_check_answers: null
  has_auth: true
  has_payments: false
  has_realtime: false
  has_ai: false
  has_background_jobs: false
---

## Why this stack

HomeFinance is a solo, after-hours web-app on a 6-week MVP timeline whose
defining guardrail is penny-accurate balances and a recommendation that is 100%
faithful to deterministic business logic — not an LLM. ASP.NET Core is the
recommended default for `(web, .NET)` and clears all four agent-friendly gates
(typed by the language, strong conventions, popular within the .NET corpus,
well-documented), with verified bootstrapper confidence so scaffolding will be
smooth. Static typing plus EF Core suit the trust-the-numbers requirement and
the rule-based priority-ladder advisor, and built-in auth covers FR-001's flat
single-tenant access control. The card scaffolds the Web API template, so the
dashboard/chart UI (FR-007/008) is added on top via Blazor.
Deploys to Azure App Service with GitHub Actions and
auto-deploy-on-merge, the starter's standard shape. Payments, realtime, AI, and
background jobs are all out of scope per the PRD.
