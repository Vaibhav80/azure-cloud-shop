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

resource "azurerm_resource_group" "product_service_rg" {
  location = "northeurope"
  name     = "products-service-resource-group"
}

resource "azurerm_storage_account" "products_service_sa" {
  name                     = "productsservicesa"
  resource_group_name      = azurerm_resource_group.product_service_rg.name
  location                 = azurerm_resource_group.product_service_rg.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  account_kind             = "StorageV2"
}

resource "azurerm_application_insights" "products_service_appin" {
  name                = "products-service-app-insights"
  application_type    = "web"
  resource_group_name = azurerm_resource_group.product_service_rg.name
  location            = azurerm_resource_group.product_service_rg.location
}

resource "azurerm_service_plan" "product_service_plan" {
  name                = "products-service-plan"
  resource_group_name = azurerm_resource_group.product_service_rg.name
  location            = azurerm_resource_group.product_service_rg.location
  os_type             = "Windows"
  sku_name            = "Y1"
}

resource "azurerm_storage_share" "products_service_storage_share" {
  name                 = "products-service-storage-share"
  quota                = 2
  storage_account_name = azurerm_storage_account.products_service_sa.name
}

resource "azurerm_windows_function_app" "products_service" {
  name                        = "products-service-function-app"
  resource_group_name         = azurerm_resource_group.product_service_rg.name
  location                    = azurerm_resource_group.product_service_rg.location
  service_plan_id             = azurerm_service_plan.product_service_plan.id
  storage_account_name        = azurerm_storage_account.products_service_sa.name
  storage_account_access_key  = azurerm_storage_account.products_service_sa.primary_access_key
  functions_extension_version = "~4"
  builtin_logging_enabled     = false
  site_config {
    always_on                              = false
    application_insights_key               = azurerm_application_insights.products_service_appin.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.products_service_appin.connection_string
    # For production systems set this to false, but consumption plan supports only 32bit workers
    use_32_bit_worker = true
    # Enable function invocations from Azure Portal.
    cors {
      allowed_origins = ["https://portal.azure.com"]
    }
    application_stack {
      node_version = "~16"
    }
  }
  app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.products_service_sa.primary_connection_string
    WEBSITE_CONTENTSHARE                     = azurerm_storage_share.products_service_storage_share.name
  }
  # The app settings changes cause downtime on the Function App. e.g. with Azure Function App Slots
  # Therefore it is better to ignore those changes and manage app settings separately off the Terraform.
  lifecycle {
    ignore_changes = [
      app_settings,
      site_config["application_stack"], // workaround for a bug when azure just "kills" your app
      tags["hidden-link: /app-insights-instrumentation-key"],
      tags["hidden-link: /app-insights-resource-id"],
      tags["hidden-link: /app-insights-conn-string"]
    ]
  }
}

resource "azurerm_app_configuration" "products_config" {
  name                = "products-service-appconfig"
  resource_group_name = azurerm_resource_group.product_service_rg.name
  location            = azurerm_resource_group.product_service_rg.location
  sku                 = "free"
}
