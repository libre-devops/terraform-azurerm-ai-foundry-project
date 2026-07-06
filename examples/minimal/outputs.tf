output "account_id" {
  description = "Parent Foundry account id."
  value       = module.ai_foundry_project.cognitive_account_id
}

output "project_ids" {
  description = "Map of project name to resource id."
  value       = module.ai_foundry_project.ids
}
