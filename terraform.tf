terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # 4.60.0 introduced azurerm_cognitive_account_project (the modern, project-based Azure AI
      # Foundry project that lives under an AIServices Cognitive account).
      version = ">= 4.60.0, < 5.0.0"
    }
  }
}
