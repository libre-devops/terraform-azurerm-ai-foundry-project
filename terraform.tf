terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    # The project is managed with azapi, not azurerm_cognitive_account_project: that resource's delete
    # sends an If-Match header with a cached ETag, and the Foundry account keeps reconciling the
    # project's ETag, so a delete shortly after create fails with 412 IfMatchPreconditionFailed. azapi
    # deletes unconditionally (no If-Match), which is reliable. azurerm is still required for the
    # provider-defined parse_resource_id function.
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0.0, < 3.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}
