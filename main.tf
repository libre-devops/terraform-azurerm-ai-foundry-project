# Azure AI Foundry projects keyed by name, created under a single AIServices Cognitive account (the
# "Foundry account"). This is the modern, project-based Foundry (Microsoft.CognitiveServices/accounts/
# projects), not the legacy Machine Learning hub. The parent account must have kind = AIServices,
# project_management_enabled = true, an identity, and a custom subdomain (all set by the
# cognitive-account module). The parent account id is passed in and parsed for the resource group and
# subscription.
#
# The project is managed with azapi rather than azurerm_cognitive_account_project because of a
# delete race in the Cognitive Services RP: the project delete is an async cascade that does its own
# ETag-conditional writes, and the Foundry account keeps reconciling the project, so a delete soon
# after create can fail with 412 IfMatchPreconditionFailed regardless of what the client sends
# (hashicorp/terraform-provider-azurerm#32614). azapi lets us neutralise it the same way Microsoft's
# AVM AI Foundry pattern module does: send a wildcard If-Match and retry the delete while the race
# still surfaces (see delete_headers and retry on the resource).
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

  # The RP's async project delete can race the account's reconciler and 412 with
  # IfMatchPreconditionFailed (see the header comment). Wildcard If-Match neutralises the front-door
  # precondition and the retry re-issues the delete (backoff, until the delete timeout) when the
  # RP-internal race still surfaces. Same mitigation as Microsoft's AVM AI Foundry pattern module.
  delete_headers = { "If-Match" = "*" }
  retry = {
    error_message_regex = ["IfMatchPreconditionFailed"]
  }

  # Export the computed fields the outputs surface.
  response_export_values = ["identity", "properties.endpoints"]
}
