# One-time identity bootstrap (run by a human, NOT in CI)

Sets up the resource group, an Azure AD app registration with **secretless OIDC** federation
to this GitHub repo, and RBAC scoped to the RG. Run once with the Azure CLI logged in
(`az login`, `az account show`). Do **not** automate these in a workflow.

## Variables

```sh
SUB=<your-subscription-id>
RG=rg-homefinance-prod
LOC=<region, e.g. westeurope>          # must pass the Phase 0 region pre-checks
APP_REG_NAME=gh-homefinance-deployer
GH=piotrp01/HomeFinance                 # OWNER/REPO — the federated subject embeds this
```

## Steps

1. **Resource group** (Bicep does not create it — keeps the CI principal least-privilege):
   ```sh
   az group create -n "$RG" -l "$LOC"
   ```

2. **App registration + service principal:**
   ```sh
   APP_ID=$(az ad app create --display-name "$APP_REG_NAME" --query appId -o tsv)
   az ad sp create --id "$APP_ID"
   ```

3. **RBAC scoped to the RG** (Contributor because the manual `infra.yml` job runs
   `az deployment group create`. If you never run infra from CI, downgrade to **Website Contributor**):
   ```sh
   az role assignment create \
     --assignee "$APP_ID" \
     --role Contributor \
     --scope "/subscriptions/$SUB/resourceGroups/$RG"
   ```

4. **Federated credential for `main`** (~5 min propagation; subject must match the branch ref exactly):
   ```sh
   az ad app federated-credential create --id "$APP_ID" --parameters '{
     "name":"gh-main",
     "issuer":"https://token.actions.githubusercontent.com",
     "subject":"repo:piotrp01/HomeFinance:ref:refs/heads/main",
     "audiences":["api://AzureADTokenExchange"]
   }'
   ```

5. **GitHub repo secrets** (no client secret — OIDC is secretless):
   - `AZURE_CLIENT_ID` = `$APP_ID`
   - `AZURE_TENANT_ID` = `az account show --query tenantId -o tsv`
   - `AZURE_SUBSCRIPTION_ID` = `$SUB`

   ```sh
   gh secret set AZURE_CLIENT_ID --body "$APP_ID"
   gh secret set AZURE_TENANT_ID --body "$(az account show --query tenantId -o tsv)"
   gh secret set AZURE_SUBSCRIPTION_ID --body "$SUB"
   ```

6. **Run infra once**, then wire the web app name as a repo **variable**:
   - Trigger the `infra` workflow (`workflow_dispatch`) — or run `az deployment group create` locally.
   - Read the `webAppName` Bicep output and set it:
     ```sh
     gh variable set AZURE_WEBAPP_NAME --body "<webAppName output>"
     ```

## Notes

- `infra.yml` references `RG` — keep `rg-homefinance-prod` in sync there (it's hardcoded in the workflow).
- If you rename the default branch, **recreate the federated credential** — the subject is branch-pinned.
- AADSTS70021 ("no matching federated identity record") = subject mismatch or <5 min since creation.
