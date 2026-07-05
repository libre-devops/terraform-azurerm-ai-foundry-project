variable "cognitive_account_id" {
  description = <<-EOT
    Resource id of the parent AIServices Cognitive account (the Azure AI Foundry account) these
    projects are created under. The account must have kind = AIServices, project_management_enabled =
    true, a managed identity, and a custom subdomain (all set by the cognitive-account module). The
    resource group and subscription are parsed from this id.
  EOT
  type        = string

  validation {
    condition     = try(provider::azurerm::parse_resource_id(var.cognitive_account_id).resource_type, "") == "accounts"
    error_message = "cognitive_account_id must be a Microsoft.CognitiveServices/accounts resource id."
  }
}

variable "api_version" {
  description = "Microsoft.CognitiveServices/accounts/projects API version used by the azapi resource. The default is a stable version azapi can schema-validate; newer versions may need schema_validation_enabled = false."
  type        = string
  default     = "2025-09-01"
}

variable "schema_validation_enabled" {
  description = "Whether azapi validates the request body against its embedded schema. Keep true with the default api_version; set false if you pin an api_version newer than the azapi provider knows."
  type        = bool
  default     = true
}

variable "location" {
  description = "Azure region for the projects. Must match the parent account's region."
  type        = string
}

variable "projects" {
  description = <<-EOT
    Azure AI Foundry projects to create under the account, keyed by project name. Each project is an
    isolated workspace with its own identity, model deployments, connections, and data. Fields:
      display_name   Friendly name shown in the Foundry portal (defaults to the project name).
      description    Free-text description.
      identity       Managed identity for the project (SystemAssigned by default).
      tags           Per-project tags (falls back to the module tags when null).
  EOT
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    tags         = optional(map(string))
    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string))
    }), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for p in values(var.projects) :
      p.identity == null ? true : contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], p.identity.type)
    ])
    error_message = "identity.type must be SystemAssigned, UserAssigned, or \"SystemAssigned, UserAssigned\"."
  }
}

variable "tags" {
  description = "Tags applied to the projects (unless a project sets its own)."
  type        = map(string)
  default     = {}
}
