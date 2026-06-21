---
bootstrapped_at: 2026-06-21T15:10:16Z
starter_id: dotnet
starter_name: .NET (ASP.NET Core webapi)
project_name: home-finance
language_family: dotnet
package_manager: dotnet
cwd_strategy: subdir-then-move
bootstrapper_confidence: verified
phase_3_status: ok
audit_command: dotnet list package --vulnerable --include-transitive
---

## Hand-off

Verbatim copy of `context/foundation/tech-stack.md`.

Frontmatter:

```yaml
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
```

### Why this stack

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

## Pre-scaffold verification

| Signal       | Value                                          | Severity | Notes                                                                 |
| ------------ | ---------------------------------------------- | -------- | --------------------------------------------------------------------- |
| npm package  | not run                                        | n/a      | non-JS starter (`language_family: dotnet`); no npm-distributed CLI    |
| GitHub repo  | not run                                        | n/a      | card `docs_url` is `learn.microsoft.com/aspnet/core`, not a GitHub repo |

No recency signal available for this starter. The slot is read-only and educational — its absence does not affect the scaffold. Local toolchain confirmed present: `dotnet --version` → 10.0.103.

## Scaffold log

**Resolved invocation**: `dotnet new webapi -n .bootstrap-scaffold --no-restore`
**Strategy**: subdir-then-move
**Exit code**: 0
**Files moved**: 6
**Conflicts (.scaffold siblings)**: none
**.gitignore handling**: absent in scaffold (the `webapi` template ships no `.gitignore`)
**.bootstrap-scaffold cleanup**: deleted

Files moved into the current directory:

- `home-finance.csproj`
- `home-finance.http`
- `Program.cs`
- `appsettings.json`
- `appsettings.Development.json`
- `Properties/launchSettings.json`

**Sentinel-name normalization (.NET-specific):** Unlike JS `create-*` CLIs where `{name}` only names the target directory, `dotnet new -n` bakes the name into project identity. The temp sentinel `.bootstrap-scaffold` therefore leaked into the project-file names (`.bootstrap-scaffold.csproj`, `.bootstrap-scaffold.http`), the `<RootNamespace>` (`_bootstrap_scaffold`), and the `.http` host-address variable. To keep the internal sentinel out of the final artifact, these were normalized to the hand-off `project_name` before move-up:

- `.bootstrap-scaffold.csproj` → `home-finance.csproj`
- `.bootstrap-scaffold.http` → `home-finance.http`
- `<RootNamespace>_bootstrap_scaffold</RootNamespace>` → `<RootNamespace>home_finance</RootNamespace>` (C#-valid identifier; hyphen not permitted in a namespace)
- `.http` variable `@_bootstrap_scaffold_HostAddress` → `@home_finance_HostAddress`

`Program.cs` uses top-level statements with no namespace declaration, so it required no change.

## Post-scaffold audit

**Tool**: `dotnet list package --vulnerable --include-transitive`
**Summary**: 0 CRITICAL, 0 HIGH, 0 MODERATE, 0 LOW
**Direct vs transitive**: the tool reported no vulnerable packages across direct or transitive dependencies

Packages were restored (`dotnet restore`, exit 0) prior to the audit because the template scaffolded with `--no-restore` and the vulnerable-package check requires a resolved dependency graph. The only direct package reference is `Microsoft.AspNetCore.OpenApi` 10.0.3.

Raw tool output:

```
The given project `home-finance` has no vulnerable packages given the current sources.
(source: https://api.nuget.org/v3/index.json)
```

Clean tree — no advisory findings on day one.

## Hints recorded but not acted on

v1 reads these hints and carries them into the audit trail but takes no automated action on them. (No `AGENTS.md` / `CLAUDE.md` generation, no CI/CD scaffolding, no feature-flag-driven scaffold changes in v1 — deferred to the future M1L4 "Memory Architecture" skill.)

| Hint                    | Value                  |
| ----------------------- | ---------------------- |
| bootstrapper_confidence | verified               |
| quality_override        | false                  |
| path_taken              | standard               |
| self_check_answers      | null                   |
| team_size               | solo                   |
| deployment_target       | azure-app-service      |
| ci_provider             | github-actions         |
| ci_default_flow         | auto-deploy-on-merge   |
| has_auth                | true                   |
| has_payments            | false                  |
| has_realtime            | false                  |
| has_ai                  | false                  |
| has_background_jobs     | false                  |

No caveats to surface: `bootstrapper_confidence` is `verified` and `quality_override` is `false`.

## Next steps

Next: a future skill will set up agent context (CLAUDE.md, AGENTS.md). For now, your project is scaffolded and verified — happy hacking.

Useful manual steps in the meantime:
- `git init` (if you have not already) to start your own repo history.
- Review any `.scaffold` siblings the conflict policy created and decide which version of each file to keep. (This run created none.)
- Address audit findings per your project's risk tolerance — the full breakdown is in this log. (This run found none.)
- The hand-off flags `has_auth: true`, a Blazor dashboard UI on top of the Web API template, EF Core, and Azure App Service deployment — none of which the `webapi` template scaffolds. These are your first build-out steps.
