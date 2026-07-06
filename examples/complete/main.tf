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
  additional_tags = { Application = "terraform-azurerm-ai-foundry-project" }
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
