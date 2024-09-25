terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.92.0"
    }
  }
  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "front_end_rg" {
  name     = "rg-azure-frontend-ne-001"
  location = "northeurope"
}

resource "azurerm_storage_account" "front_end_storage" {
  name                     = "azureshopne001"
  location                 = azurerm_resource_group.front_end_rg.location
  resource_group_name      = azurerm_resource_group.front_end_rg.name
  account_replication_type = "LRS"
  account_tier             = "Standard"
  account_kind             = "StorageV2"

  static_website {
    index_document = "index.html"
  }
}


resource "azurerm_storage_container" "front_end_container" {
  name                 = "$web"
  storage_account_name = azurerm_storage_account.front_end_storage.name
}

resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.front_end_storage.name
  storage_container_name = azurerm_storage_container.front_end_container.name
  type                   = "Block"
  source                 = "${path.module}/../dist/index.html"
  content_type           = "text/html"
}

resource "azurerm_storage_blob" "mock_service_worker_js" {
  name                   = "mockServiceWorker.js"
  storage_account_name   = azurerm_storage_account.front_end_storage.name
  storage_container_name = azurerm_storage_container.front_end_container.name
  type                   = "Block"
  source                 = "${path.module}/../dist/mockServiceWorker.js"
  content_type           = "text/html"
}

resource "azurerm_storage_blob" "asset_js" {
  for_each               = fileset("${path.module}/../dist/assets", "*.js")
  name                   = "assets/${each.value}"
  storage_account_name   = azurerm_storage_account.front_end_storage.name
  storage_container_name = azurerm_storage_container.front_end_container.name
  type                   = "Block"
  source                 = "${path.module}/../dist/assets/${each.value}"
  content_type           = "application/javascript"
}
