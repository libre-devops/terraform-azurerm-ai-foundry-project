<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure AI Foundry Project

Azure AI Foundry projects created under an AIServices Cognitive account: the modern, project-based
Foundry, not the legacy Machine Learning hub.

[![CI](https://github.com/libre-devops/terraform-azurerm-ai-foundry-project/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-ai-foundry-project/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-ai-foundry-project?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-ai-foundry-project/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-ai-foundry-project)](./LICENSE)

---

## Overview

Azure AI Foundry projects keyed by name, created under a single AIServices Cognitive account (the
"Foundry account"). Each project is an isolated workspace with its own identity, model deployments,
connections, and data assets.

This is the **modern, project-based Foundry** (`Microsoft.CognitiveServices/accounts/projects`), the
default in the Azure AI Foundry portal, not the legacy Machine Learning hub (`azurerm_ai_foundry` +
`azurerm_ai_foundry_project`, which are built on Azure ML workspaces and require a Key Vault and a
Storage account). Projects here need only the parent account.

The parent account must be an **AIServices** Cognitive account with `project_management_enabled = true`,
a managed identity, and a custom subdomain. The Libre DevOps
[`cognitive-account`](https://registry.terraform.io/modules/libre-devops/cognitive-account/azurerm/latest)
module sets all of those, so the usual pattern is to create the account with that module and pass its
id to this one. The account id is parsed for the resource group and subscription.

## Usage

```hcl
module "cognitive_account" {
  source  = "libre-devops/cognitive-account/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-prd-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  cognitive_accounts = {
    "ais-ldo-uks-prd-001" = {
      kind                       = "AIServices"
      project_management_enabled = true
    }
  }
}

module "ai_foundry_project" {
  source  = "libre-devops/ai-foundry-project/azurerm"
  version = "~> 4.0"

  cognitive_account_id = module.cognitive_account.ids["ais-ldo-uks-prd-001"]
  location             = "uksouth"
  tags                 = module.tags.tags

  projects = {
    "aifp-ldo-uks-prd-001" = {
      display_name = "Retrieval agent"
      description  = "RAG agent project"
    }
  }
}
```

## Examples

- [`examples/minimal`](./examples/minimal) - one Foundry account and a single project on it.
- [`examples/complete`](./examples/complete) - the full 3-module RAG composition: a Foundry account
  (with a chat deployment), an Azure AI Search service, two projects, and a role assignment granting
  the RAG project's identity read access to the search index.

## Developing

Local work needs **PowerShell 7+** and **[`just`](https://github.com/casey/just)**, because the recipes
wrap the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers)
PowerShell module (the same engine the `libre-devops/terraform-azure` action runs in CI). Install
just with `brew install just`, or `uv tool add rust-just` then `uv run just <recipe>`.

Run `just` to list recipes: `just update-ldo-pwsh` (install or force-update LibreDevOpsHelpers from
PSGallery), `just validate`, `just scan` (Trivy only), `just pwsh-analyze` (PSScriptAnalyzer only),
`just plan`, `just apply`, `just destroy`, `just e2e`, `just test`, and `just docs` (the
plan/apply/destroy recipes mirror the action, including the storage firewall dance; `just e2e`
applies an example then always destroys it, defaulting to `minimal`, so nothing is left running).
Releasing is also `just`:
`just increment-release [patch|minor|major]` bumps, tags, and publishes a GitHub release, and the
Terraform Registry picks up the tag.

## Security scan exceptions

This module is scanned with [Trivy](https://github.com/aquasecurity/trivy); HIGH and CRITICAL
findings fail the build. Any waiver is a deliberate, reviewed decision, never a way to quiet a
finding that should be fixed. Waivers live in [`.trivyignore.yaml`](./.trivyignore.yaml) (the
machine-applied source of truth, passed to Trivy with `--ignorefile`) and are mirrored in the table
below so the reason is auditable.

| Trivy ID | Resource | Finding | Justification |
|----------|----------|---------|---------------|
| _None_   |          |         |               |

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here. Where the finding is out of this module's
scope, point the justification at the Libre DevOps module that does address it (for example the
private-endpoint module). Both the file and this table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.
