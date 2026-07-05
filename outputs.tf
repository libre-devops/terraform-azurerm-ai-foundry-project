output "ids" {
  description = "Map of project name to its resource id."
  value       = { for k, v in azapi_resource.this : k => v.id }
}

output "ids_zipmap" {
  description = "Map of project name to a { name, id } object, for passing where both are needed together."
  value       = { for k, v in azapi_resource.this : k => { name = v.name, id = v.id } }
}

output "names" {
  description = "The project names."
  value       = keys(azapi_resource.this)
}

output "endpoints" {
  description = "Map of project name to its endpoints map (the per-project Foundry endpoints)."
  value       = { for k, v in azapi_resource.this : k => try(v.output.properties.endpoints, {}) }
}

output "identities" {
  description = "Map of project name to its managed identity { principal_id, tenant_id } (principal_id is populated for system-assigned identities)."
  value = {
    for k, v in azapi_resource.this : k => try({
      principal_id = v.output.identity.principalId
      tenant_id    = v.output.identity.tenantId
    }, null)
  }
}

output "cognitive_account_id" {
  description = "Resource id of the parent Cognitive account the projects belong to."
  value       = var.cognitive_account_id
}

output "resource_group_name" {
  description = "Resource group name parsed from cognitive_account_id."
  value       = local.resource_group_name
}

output "subscription_id" {
  description = "Subscription id parsed from cognitive_account_id."
  value       = local.account.subscription_id
}

output "tags" {
  description = "The tags applied to the projects."
  value       = var.tags
}
