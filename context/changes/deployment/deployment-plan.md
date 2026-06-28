# Azure App Service Integration — HomeFinance

## Context

`context/foundation/infrastructure.md` recorded **Azure App Service** as the deployment target for HomeFinance (a .NET 10 / ASP.NET Core finance app). The repo is still the raw scaffold — `Program.cs` has only the `/weatherforecast` endpoint, and there is **no CI, no IaC, no remote, no DB**. This plan stands up the *deployment integration* (provisioning + auto-deploy-on-push) for the current scaffold so the delivery loop exists before product features land. Outcome: every push to `main` builds and deploys to a live `*.azurewebsites.net` URL via secretless OIDC, with infrastructure reproducible from Bicep in the repo.

**Decisions locked in (from interview):**
- **Database:** none yet — pipeline first. Design so DB drops in cleanly later.
- **Tier:** Free **F1** Linux for the first smoke test. Accepts F1 limits (no Always On / WebSockets / slots, 60 CPU-min/day, app sleeps) — fine for the API scaffold.
- **Scope:** provision infra + auto-deploy-on-push to `main` for the current scaffold + minimal app readiness (`/healthz`). Defer auth / Blazor / EF.
- **Provisioning:** **Bicep IaC** committed to the repo, with a one-time `az` bootstrap for identity.

**Key facts that shape the work:**
- Output assembly is `home-finance.dll` (csproj `RootNamespace home_finance`, project file `home-finance.csproj`).
- Linux App Service injects the port; **do not** set `ASPNETCORE_URLS`/`UseUrls` — Kestrel binds automatically.
- `.NET 10` Linux runtime id is `DOTNETCORE|10.0` (Bicep) / `DOTNETCORE:10.0` (az) — still "Preview"-tagged in some regions; verify before provisioning.
- No git remote exists yet → repo creation is a prerequisite (federated subject needs `OWNER/REPO`).

---

## Phase 0 — Prerequisites (one-time, human)

- [x] Create the GitHub repository and add the remote: `git remote add origin <url>`, then `git push -u origin main`. *(Blocker: the OIDC federated credential subject embeds `repo:OWNER/REPO`.)* — repo `piotrp01/HomeFinance`, remote set.
- [x] Confirm Azure CLI is logged in (`az account show`) and pick the target subscription + region. — `Subscription1` (`bbf9aa66…`), region **Poland Central**.
- [x] **Region pre-checks (edge case):**
  - F1 Linux availability: `az appservice list-locations --sku F1 --linux-workers-enabled` → if the region rejects F1, choose a nearby region or fall back to B1. — Poland Central supports F1 Linux.
  - .NET 10 runtime GA in region: `az webapp list-runtimes --os linux | grep -i dotnet` → confirm `DOTNETCORE|10.0` is listed. If absent, switch region (preferred) — do **not** downgrade the target framework. — `DOTNETCORE|10.0` confirmed GA.

## Phase 1 — App-side minimal readiness

Files: `Program.cs`, new `appsettings.Production.json`. No new packages (health checks are in the shared framework).

- [x] Add `builder.Services.AddHealthChecks();` and `app.MapHealthChecks("/healthz");` (before `app.Run()`). No DB check yet — `AddDbContextCheck` drops in with the DB phase.
- [x] Keep `UseHttpsRedirection()` (App Service terminates TLS and forwards `X-Forwarded-Proto`; no redirect loop expected).
- [x] Add secret-free `appsettings.Production.json` with quieter logging (`Default: Warning`). Leave `AllowedHosts: "*"` until a custom domain exists.
- [x] Do **not** hardcode ports/URLs and keep OpenAPI Dev-only (already the case).

## Phase 2 — Bicep IaC (`infra/`)

Files: `infra/main.bicep`, `infra/main.parameters.json`. `targetScope = 'resourceGroup'` (the RG is created by the Phase 3 bootstrap, not Bicep — keeps the CI principal least-privilege).

- [x] **App Service Plan** (`Microsoft.Web/serverfarms`): `kind: 'linux'`, **`properties.reserved: true`** (mandatory for Linux), `sku: { name: skuName, tier: ... }`. Parameterize `skuName` (default `F1`) so the **B1 fallback is a one-line param change**.
- [x] **Web App** (`Microsoft.Web/sites`): `kind: 'app,linux'`, `identity: { type: 'SystemAssigned' }` (provision now so Key Vault drops in later), `httpsOnly: true`, `serverFarmId` → plan.
  - `siteConfig.linuxFxVersion: 'DOTNETCORE|10.0'`
  - `siteConfig.alwaysOn: skuName == 'F1' ? false : true`  ← **F1 requires `false` or the deploy fails.**
  - `siteConfig.webSocketsEnabled: false` (F1; flip to `true` only at B1+ for Blazor Server)
  - `siteConfig.ftpsState: 'Disabled'`, `minTlsVersion: '1.2'`, `healthCheckPath: '/healthz'`
  - `siteConfig.appSettings`: `SCM_DO_BUILD_DURING_DEPLOYMENT=false`, `ASPNETCORE_ENVIRONMENT=Production`
- [x] **Naming:** `resourceToken = uniqueString(resourceGroup().id)`; web app `app-homefinance-${env}-${resourceToken}` (azurewebsites.net is a global namespace), plan `plan-homefinance-${env}`. Params: `appName`, `location`, `skuName`, `environmentName`. — resolved to `app-homefinance-prod-46rxlppp4evum`.
- [x] **Outputs:** `webAppName`, `webAppDefaultHostname` — consumed by the workflow/verification.
- [x] **Do not** set `WEBSITE_RUN_FROM_PACKAGE` for the first smoke test (interacts awkwardly with zip deploy; revisit later for atomic deploys).

## Phase 3 — One-time identity bootstrap (az CLI, human)

Document as a checklist in `infra/bootstrap.md` (do **not** auto-run in CI). Vars: `SUB`, `RG=rg-homefinance-prod`, `LOC`, `APP_REG_NAME=gh-homefinance-deployer`, `GH=OWNER/REPO`.

- [x] `az group create -n $RG -l $LOC` — `rg-homefinance-prod` in Poland Central.
- [x] `az ad app create --display-name $APP_REG_NAME` → capture `appId`; then `az ad sp create --id <appId>`. — `appId c7603bc5-f45b-4bc1-b19d-61bb539fe832`, SP object id `6b6e2ca6-…`.
- [x] RBAC scoped to the RG: `az role assignment create --assignee <appId> --role Contributor --scope /subscriptions/$SUB/resourceGroups/$RG`. *(Contributor because CI's manual infra job runs `az deployment group create`. If infra is never run from CI, downgrade to **Website Contributor**.)* — **NOTE:** `az role assignment create` failed with a persistent `MissingSubscription` CLI bug; assigned via direct ARM `az rest` PUT instead. Also: the tenant's Contributor role-def id is `b24988ac-6180-42a0-ab88-20f7382dd24c` (not the usual well-known GUID).
- [x] Federated credential for `main`:
  ```
  az ad app federated-credential create --id <appId> --parameters '{
    "name":"gh-main","issuer":"https://token.actions.githubusercontent.com",
    "subject":"repo:OWNER/REPO:ref:refs/heads/main","audiences":["api://AzureADTokenExchange"]}'
  ```
  *(~5 min propagation; subject must match the branch ref exactly.)* — created `gh-main`, subject `repo:piotrp01/HomeFinance:ref:refs/heads/main`.
- [x] Set GitHub repo secrets: `AZURE_CLIENT_ID` (appId), `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`. No client secret — OIDC is secretless. — all three set via `gh secret set`.
- [x] After the first infra deploy, set repo **variable** `AZURE_WEBAPP_NAME` from the Bicep `webAppName` output. — set to `app-homefinance-prod-46rxlppp4evum`.

## Phase 4 — GitHub Actions (`.github/workflows/`)

**Two workflows** — infra deploy is deliberate/manual; code deploy is automatic.

- [x] `infra.yml` — `workflow_dispatch` only. Steps: `azure/login@v2` (OIDC) → `az deployment group create -g <RG> -f infra/main.bicep -p @infra/main.parameters.json`. Rationale: infra changes are rare and re-provisioning on every push wastes F1 quota. (Trade-off: no auto drift reconciliation — acceptable now.) — created; uses `azure/cli@v2` for the deployment step. *(First provision was run locally, not via this workflow, since its OIDC subject is pinned to `main` and the code is still on a feature branch.)*
- [x] `azure-deploy.yml` — `on: push: branches: [main]` + `workflow_dispatch`.
  - `permissions: { id-token: write, contents: read }` (required for OIDC).
  - `concurrency: { group: deploy-main, cancel-in-progress: true }` (avoid overlapping deploys eating F1 quota).
  - Steps: `actions/checkout@v4` → `actions/setup-dotnet@v4` (`dotnet-version: 10.x`) → `dotnet publish home-finance.csproj -c Release -o ./publish` → `azure/login@v2` (client/tenant/subscription from secrets) → `azure/webapps-deploy@v3` with `app-name: ${{ vars.AZURE_WEBAPP_NAME }}` and `package: ./publish` (pass the folder, sidestepping the `home-finance.dll` naming concern).

## Phase 5 — Edge cases & extra support steps

- [ ] **AADSTS70021 "no matching federated identity record"**: subject mismatch. Verify subject is exactly `repo:OWNER/REPO:ref:refs/heads/main`, that the trigger was a push to `main` (PRs/tags need different subjects), wait ~5 min after creating the credential, and that `AZURE_TENANT_ID`/`AZURE_CLIENT_ID` are correct.
- [ ] **main vs master**: you mentioned "master"; this repo is `main`. The federated subject is branch-pinned — keep the workflow trigger branch and the federated subject in sync. If you ever rename the branch, recreate the federated credential.
- [ ] **.NET 10 not GA in region**: re-check `az webapp list-runtimes --os linux` on deploy day; if missing, switch region. Self-contained publish (`--self-contained -r linux-x64`) is a last-resort fallback (bloats the package).
- [ ] **F1 deploy fails with SKU error**: almost always `alwaysOn` truthy on F1 — ensure it resolves to `false`. WebSockets must stay disabled on F1.
- [ ] **F1 60 CPU-min/day quota**: repeated deploys/load can exhaust it → 403/quota errors until UTC reset. If smoke tests flake, check quota before debugging code; upgrade to B1 if it bites.
- [ ] **`SCM_DO_BUILD_DURING_DEPLOYMENT` missing**: Oryx tries to rebuild the uploaded output and may fail/double-build. Confirm it's `false` in Bicep app settings.
- [ ] **"App didn't start" on first deploy**: enable + tail logs — `az webapp log config --application-logging filesystem -g <RG> -n <app>` then `az webapp log tail -g <RG> -n <app>`. Single-project publish auto-detects `home-finance.dll`; only set a startup command (`dotnet home-finance.dll`) if auto-detection ever fails.
- [ ] **Cold start**: F1 has no Always On, so the first request after idle is slow — retry once before calling it a failure.

## Phase 6 — Verification (end-to-end)

- [ ] GitHub Actions `azure-deploy` run is green (inspect `azure/login` + `webapps-deploy` steps). — **pending merge to `main`** (deploy fires on push to `main`).
- [x] `az webapp show -g <RG> -n <app> --query state` → `Running`. — confirmed `Running`.
- [ ] `curl -i https://<app>.azurewebsites.net/healthz` → `200 Healthy`. — **pending first code deploy.**
- [ ] `curl -s https://<app>.azurewebsites.net/weatherforecast` → JSON array of 5 forecasts. — **pending first code deploy.**
- [ ] `az webapp log tail -g <RG> -n <app>` → Kestrel "Now listening on…", no startup exceptions. — **pending first code deploy.**

## Explicitly deferred (with upgrade triggers)

- [ ] **DB / EF Core**: trigger = first persisted feature. Drop-in ready (managed identity exists; add connection string app setting + `AddDbContextCheck`). DB engine (Azure SQL vs PostgreSQL) chosen then — note Postgres/Npgsql needs explicit `numeric(19,4)` for the penny-accuracy guardrail.
- [ ] **Key Vault + secrets**: not provisioned now (no secrets yet). Trigger = first real secret → add `Microsoft.KeyVault/vaults`, grant the web app's identity "Key Vault Secrets User", reference via `@Microsoft.KeyVault(SecretUri=...)`.
- [ ] **Slots / zero-downtime + Always On**: trigger = move to Standard S1+ → add `staging` slot + swap; flip `alwaysOn`.
- [ ] **Blazor / WebSockets / SignalR**: trigger = interactive UI → B1+ and `webSocketsEnabled: true` (+ ARR affinity, or Azure SignalR for scale-out).
- [ ] **Auth**: trigger = first protected endpoint.

## Critical files

- `Program.cs` — add `/healthz`.
- `appsettings.Production.json` *(new)* — quiet production logging.
- `infra/main.bicep`, `infra/main.parameters.json` *(new)* — plan + site + system-assigned identity.
- `infra/bootstrap.md` *(new)* — one-time identity/RBAC/federated-credential checklist.
- `.github/workflows/azure-deploy.yml` *(new)* — OIDC build + deploy on push to `main`.
- `.github/workflows/infra.yml` *(new)* — manual Bicep provisioning.
