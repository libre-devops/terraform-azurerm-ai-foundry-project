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

> The project is managed with **azapi** (`azapi_resource`), not `azurerm_cognitive_account_project`.
> The Cognitive Services RP's project delete is an async cascade that does its own ETag-conditional
> writes, and the Foundry account keeps reconciling the project, so a delete soon after create can
> fail with `412 IfMatchPreconditionFailed` no matter which client sends it
> ([azurerm#32614](https://github.com/hashicorp/terraform-provider-azurerm/issues/32614)). azapi lets
> the module absorb it the same way Microsoft's
> [AVM AI Foundry pattern module](https://github.com/Azure/terraform-azurerm-avm-ptn-aiml-ai-foundry)
> does: a wildcard `If-Match` on delete plus a retry on that error until it lands. The module
> interface and outputs are unchanged.

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
- [`examples/complete`](./examples/complete) - a Foundry account with a chat deployment and two
  projects on it, each with a display name, description, and identity.

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 2.0.0, < 3.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | >= 2.0.0, < 3.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_version"></a> [api\_version](#input\_api\_version) | Microsoft.CognitiveServices/accounts/projects API version used by the azapi resource. The default is a stable version azapi can schema-validate; newer versions may need schema\_validation\_enabled = false. | `string` | `"2025-09-01"` | no |
| <a name="input_cognitive_account_id"></a> [cognitive\_account\_id](#input\_cognitive\_account\_id) | Resource id of the parent AIServices Cognitive account (the Azure AI Foundry account) these<br/>projects are created under. The account must have kind = AIServices, project\_management\_enabled =<br/>true, a managed identity, and a custom subdomain (all set by the cognitive-account module). The<br/>resource group and subscription are parsed from this id. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the projects. Must match the parent account's region. | `string` | n/a | yes |
| <a name="input_projects"></a> [projects](#input\_projects) | Azure AI Foundry projects to create under the account, keyed by project name. Each project is an<br/>isolated workspace with its own identity, model deployments, connections, and data. Fields:<br/>  display\_name   Friendly name shown in the Foundry portal (defaults to the project name).<br/>  description    Free-text description.<br/>  identity       Managed identity for the project (SystemAssigned by default).<br/>  tags           Per-project tags (falls back to the module tags when null). | <pre>map(object({<br/>    display_name = optional(string)<br/>    description  = optional(string)<br/>    tags         = optional(map(string))<br/>    identity = optional(object({<br/>      type         = optional(string, "SystemAssigned")<br/>      identity_ids = optional(list(string))<br/>    }), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_schema_validation_enabled"></a> [schema\_validation\_enabled](#input\_schema\_validation\_enabled) | Whether azapi validates the request body against its embedded schema. Keep true with the default api\_version; set false if you pin an api\_version newer than the azapi provider knows. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the projects (unless a project sets its own). | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cognitive_account_id"></a> [cognitive\_account\_id](#output\_cognitive\_account\_id) | Resource id of the parent Cognitive account the projects belong to. |
| <a name="output_endpoints"></a> [endpoints](#output\_endpoints) | Map of project name to its endpoints map (the per-project Foundry endpoints). |
| <a name="output_identities"></a> [identities](#output\_identities) | Map of project name to its managed identity { principal\_id, tenant\_id } (principal\_id is populated for system-assigned identities). |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of project name to its resource id. |
| <a name="output_ids_zipmap"></a> [ids\_zipmap](#output\_ids\_zipmap) | Map of project name to a { name, id } object, for passing where both are needed together. |
| <a name="output_names"></a> [names](#output\_names) | The project names. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name parsed from cognitive\_account\_id. |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | Subscription id parsed from cognitive\_account\_id. |
| <a name="output_tags"></a> [tags](#output\_tags) | The tags applied to the projects. |
<!-- END_TF_DOCS -->
