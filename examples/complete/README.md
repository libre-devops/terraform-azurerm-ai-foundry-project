<!--
  Header for the complete example README. Edit this file, then run `just docs`
  (or ./Sort-LdoTerraform.ps1 -IncludeExamples) to regenerate the section between the markers.
  The example's main.tf is embedded into the README automatically (see .terraform-docs.yml).
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="200">
    </picture>
  </a>
</div>

# Complete example

Exercises the fuller surface of this module. The environment comes from the Terraform workspace
(`terraform.workspace`), not a variable. Run it with `just e2e complete`, which applies the stack
then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  ais_name  = "ais-${var.short}-${var.loc}-${terraform.workspace}-002"
  proj_rag  = "aifp-${var.short}-${var.loc}-${terraform.workspace}-002"
  proj_eval = "aifp-${var.short}-${var.loc}-${terraform.workspace}-003"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  environment     = "prd"
  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azapi-ai-foundry-project" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# The parent Azure AI Foundry (AIServices) account, with project management enabled and a small chat
# deployment the projects can share.
module "cognitive_account" {
  source  = "libre-devops/cognitive-account/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  cognitive_accounts = {
    (local.ais_name) = {
      kind                       = "AIServices"
      project_management_enabled = true

      deployments = {
        "gpt-5-mini" = {
          model = { name = "gpt-5-mini", version = "2025-08-07" }
          sku   = { name = "GlobalStandard", capacity = 10 }
        }
      }
    }
  }
}

# Complete call: two projects on the account, each with a display name, description, and identity.
module "ai_foundry_project" {
  source = "../../"

  cognitive_account_id = module.cognitive_account.ids[local.ais_name]
  location             = local.location
  tags                 = module.tags.tags

  projects = {
    (local.proj_rag) = {
      display_name = "Retrieval agent"
      description  = "RAG agent project with its own connections and data."
      identity     = { type = "SystemAssigned" }
    }
    (local.proj_eval) = {
      display_name = "Evaluations"
      description  = "Offline evaluation and red-teaming workspace."
      identity     = { type = "SystemAssigned" }
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | >= 2.0.0, < 3.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ai_foundry_project"></a> [ai\_foundry\_project](#module\_ai\_foundry\_project) | ../../ | n/a |
| <a name="module_cognitive_account"></a> [cognitive\_account](#module\_cognitive\_account) | libre-devops/cognitive-account/azurerm | ~> 4.0 |
| <a name="module_rg"></a> [rg](#module\_rg) | libre-devops/rg/azurerm | ~> 4.0 |
| <a name="module_tags"></a> [tags](#module\_tags) | libre-devops/tags/azurerm | ~> 4.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployed_branch"></a> [deployed\_branch](#input\_deployed\_branch) | Git branch the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_branch. | `string` | `""` | no |
| <a name="input_deployed_repo"></a> [deployed\_repo](#input\_deployed\_repo) | Repository URL the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_repo. | `string` | `""` | no |
| <a name="input_loc"></a> [loc](#input\_loc) | Outfix: short Azure region code used in resource names (for example uks). | `string` | `"uks"` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | Map of short region codes to Azure region slugs. | `map(string)` | <pre>{<br/>  "eus": "eastus",<br/>  "euw": "westeurope",<br/>  "uks": "uksouth",<br/>  "ukw": "ukwest"<br/>}</pre> | no |
| <a name="input_short"></a> [short](#input\_short) | Infix: short product code used in resource names. | `string` | `"ldo"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | Parent Foundry account id. |
| <a name="output_project_endpoints"></a> [project\_endpoints](#output\_project\_endpoints) | Map of project name to its endpoints. |
| <a name="output_project_ids"></a> [project\_ids](#output\_project\_ids) | Map of project name to resource id. |
<!-- END_TF_DOCS -->
