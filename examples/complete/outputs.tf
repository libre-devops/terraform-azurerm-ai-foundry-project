output "account_id" {
  description = "The Foundry (AIServices) account id."
  value       = module.cognitive_account.ids[local.ais_name]
}

output "project_ids" {
  description = "Map of project name to resource id."
  value       = module.ai_foundry_project.ids
}

output "search_service_id" {
  description = "The search service id the RAG project can read."
  value       = module.search_service.ids[local.srch_name]
}
