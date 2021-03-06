## Not using azuread_group as it is based on the ActiveDirectory Graph and does not support the delete when ran from a service principal
# Need AzureAd provider to move to Microsoft Graph to support deletion

# resource "azuread_group" "developers_rover" {
#   count = var.enable_collaboration == true ? 1 : 0

#   name = "${local.prefix}caf-level0-rover-developers"
# }

locals {
  adgroup = "caf${local.prefix}-level0-rover-developers"
}


resource "null_resource" "ad_group_devops_rover" {
  count = var.enable_collaboration == true ? 1 : 0


  provisioner "local-exec" {
      command     = "/usr/bin/az ad group create --display-name '${local.adgroup}' --mail-nickname '${local.adgroup}'"
      on_failure  = fail

  }

  provisioner "local-exec" {
      command = "sleep 60"
  }

  # provisioner "local-exec" {
  #     command     = "az ad group delete --group $name"
  #     interpreter = ["/bin/sh"]
  #     on_failure  = fail
  #     when        = "destroy"

  #     environment = {
  #       name       = local.adgroup
  #     }
  # }

}


data "azuread_group" "devops_rover" {
  count = var.enable_collaboration == true ? 1 : 0
  depends_on = [ null_resource.ad_group_devops_rover ]
  name = local.adgroup
}


resource "azuread_group_member" "bootstrap_user" {
  count = var.enable_collaboration == true ? 1 : 0
  
  group_object_id   = data.azuread_group.devops_rover.0.id
  member_object_id  = var.logged_user_objectId

  lifecycle {
    ignore_changes = [
      member_object_id,
    ]
  }
}



###
#   Grant devops app contributor on the current subscription to be able to deploy the blueprint_azure_devops
###
resource "azurerm_role_assignment" "developers_rover" {
  count = var.enable_collaboration == true ? 1 : 0
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_group.devops_rover.0.id
}

resource "azurerm_key_vault_access_policy" "developers_rover" {
  count = var.enable_collaboration == true ? 1 : 0
  key_vault_id = azurerm_key_vault.launchpad.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azuread_group.devops_rover.0.id

  key_permissions = []

  secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete"
  ]

}

resource "azurerm_role_assignment" "storage_blob_contributor_developers_rover" {
  count = var.enable_collaboration == true ? 1 : 0
  scope                = azurerm_storage_account.stg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_group.devops_rover.0.id
}
