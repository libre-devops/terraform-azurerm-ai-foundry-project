# Plan-time tests for the module. The providers are mocked, so no credentials, no features block,
# and no cloud calls are needed:
#   terraform init -backend=false && terraform test

mock_provider "azapi" {}
mock_provider "azurerm" {}

variables {
  location             = "uksouth"
  cognitive_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.CognitiveServices/accounts/ais-ldo-uks-tst-01"

  projects = {
    "aifp-ldo-uks-tst-01" = {
      display_name = "Test project"
    }
  }
}

# A project is created under the account (via azapi) with a system-assigned identity by default.
run "creates_project" {
  command = plan

  assert {
    condition     = azapi_resource.this["aifp-ldo-uks-tst-01"].parent_id == var.cognitive_account_id
    error_message = "The project should be parented to the supplied cognitive account."
  }

  assert {
    condition     = azapi_resource.this["aifp-ldo-uks-tst-01"].location == "uksouth"
    error_message = "The project should be created in the requested location."
  }

  assert {
    condition     = startswith(azapi_resource.this["aifp-ldo-uks-tst-01"].type, "Microsoft.CognitiveServices/accounts/projects@")
    error_message = "The project should be the CognitiveServices accounts/projects azapi type."
  }

  assert {
    condition     = azapi_resource.this["aifp-ldo-uks-tst-01"].identity[0].type == "SystemAssigned"
    error_message = "The project should get a system-assigned identity by default."
  }

  assert {
    condition     = length(azapi_resource.this) == 1
    error_message = "One project should be created per map entry."
  }
}

# The resource group is parsed from the account id and exposed as an output.
run "parses_resource_group_from_account_id" {
  command = plan

  assert {
    condition     = output.resource_group_name == "rg-ldo-uks-tst-01"
    error_message = "resource_group_name should be parsed from cognitive_account_id."
  }
}

# Validation: a non-account id (a bare resource group id) is rejected.
run "rejects_non_account_id" {
  command = plan

  variables {
    cognitive_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01"
  }

  expect_failures = [var.cognitive_account_id]
}

# Validation: an invalid identity type is rejected.
run "rejects_invalid_identity_type" {
  command = plan

  variables {
    projects = {
      "aifp-ldo-uks-tst-01" = {
        identity = { type = "None" }
      }
    }
  }

  expect_failures = [var.projects]
}
