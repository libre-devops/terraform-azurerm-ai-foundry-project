locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
  ais_name  = "ais-${var.short}-${var.loc}-${terraform.workspace}-001"
  proj_name = "aifp-${var.short}-${var.loc}-${terraform.workspace}-001"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# The parent Azure AI Foundry (AIServices) account, with project management enabled.
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
    }
  }
}

# Minimal call: a single project on the account.
module "ai_foundry_project" {
  source = "../../"

  cognitive_account_id = module.cognitive_account.ids[local.ais_name]
  location             = local.location
  tags                 = module.tags.tags

  projects = {
    (local.proj_name) = {
      display_name = "Minimal project"
    }
  }
}
