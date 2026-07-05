# Azure AI Foundry projects keyed by name, created under a single AIServices Cognitive account (the
# "Foundry account"). This is the modern, project-based Foundry (Microsoft.CognitiveServices/accounts/
# projects), not the legacy Machine Learning hub. The parent account must have kind = AIServices,
# project_management_enabled = true, an identity, and a custom subdomain (all set by the
# cognitive-account module). Each project gets its own identity, agents, deployments, and connections.
# The parent account id is passed in and parsed for the resource group and subscription.
locals {
  account             = provider::azurerm::parse_resource_id(var.cognitive_account_id)
  resource_group_name = local.account.resource_group_name
}

resource "azurerm_cognitive_account_project" "this" {
  for_each = var.projects

  cognitive_account_id = var.cognitive_account_id
  location             = var.location
  tags                 = each.value.tags != null ? each.value.tags : var.tags

  name         = each.key
  display_name = each.value.display_name
  description  = each.value.description

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
}
