locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  ais_name  = "ais-${var.short}-${var.loc}-${terraform.workspace}-002"
  srch_name = "srch-${var.short}-${var.loc}-${terraform.workspace}-002"
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

# Complete call: a full RAG-style composition of the three AI modules. The Foundry account holds the
# models, the search service is the retrieval index, and the Foundry projects are the agent
# workspaces. The RAG project's identity is granted read access to the search index to wire them up.

# 1. The Azure AI Foundry (AIServices) account with project management and a small chat deployment.
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

# 2. The Azure AI Search service (retrieval side of RAG).
module "search_service" {
  source  = "libre-devops/search-service/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  search_services = {
    (local.srch_name) = {
      sku                 = "basic"
      semantic_search_sku = "free"
      identity            = { type = "SystemAssigned" }
    }
  }
}

# 3. The Foundry projects on the account: a RAG agent workspace and an evaluations workspace.
module "ai_foundry_project" {
  source = "../../"

  cognitive_account_id = module.cognitive_account.ids[local.ais_name]
  location             = local.location
  tags                 = module.tags.tags

  projects = {
    (local.proj_rag) = {
      display_name = "Retrieval agent"
      description  = "RAG agent project; reads the search index below."
      identity     = { type = "SystemAssigned" }
    }
    (local.proj_eval) = {
      display_name = "Evaluations"
      description  = "Offline evaluation and red-teaming workspace."
      identity     = { type = "SystemAssigned" }
    }
  }
}

# 4. Wire them up: grant the RAG project's managed identity read access to the search index.
module "rag_role_assignment" {
  source  = "libre-devops/role-assignment/azurerm"
  version = "~> 4.0"

  role_assignments = {
    "rag-project-reads-search" = {
      scope         = module.search_service.ids[local.srch_name]
      principal_ids = [module.ai_foundry_project.identities[local.proj_rag].principal_id]
      role_names    = ["Search Index Data Reader"]
    }
  }
}
