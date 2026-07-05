# Azure AI Foundry projects keyed by name, created under a single AIServices Cognitive account (the
# "Foundry account"). This is the modern, project-based Foundry (Microsoft.CognitiveServices/accounts/
# projects), not the legacy Machine Learning hub. The parent account must have kind = AIServices,
# project_management_enabled = true, an identity, and a custom subdomain (all set by the
# cognitive-account module). The parent account id is passed in and parsed for the resource group and
# subscription.
#
# The project is managed with azapi rather than azurerm_cognitive_account_project: that resource's
# delete uses an ETag If-Match precondition, and the Foundry account keeps reconciling the project's
# ETag, so deleting shortly after create fails with 412 IfMatchPreconditionFailed. azapi's
# unconditional delete avoids that.
locals {
  account             = provider::azurerm::parse_resource_id(var.cognitive_account_id)
  resource_group_name = local.account.resource_group_name
}

resource "azapi_resource" "this" {
  for_each = var.projects

  type                      = "Microsoft.CognitiveServices/accounts/projects@${var.api_version}"
  name                      = each.key
  parent_id                 = var.cognitive_account_id
  location                  = var.location
  tags                      = each.value.tags != null ? each.value.tags : var.tags
  schema_validation_enabled = var.schema_validation_enabled

  body = {
    properties = merge(
      each.value.display_name != null ? { displayName = each.value.display_name } : {},
      each.value.description != null ? { description = each.value.description } : {},
    )
  }

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  # Export the computed fields the outputs surface.
  response_export_values = ["identity", "properties.endpoints"]
}
