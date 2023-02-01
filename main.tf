provider "azurerm" {
    features {}
}
resource "azurerm_resource_group" "app_grp" {
    name = "app-resources"
    location = "Central India"
}
resource "azurerm_virtual_network" "app_network" {
    name = "app-network"
    resource_group_name = "app_grp"
    location = "Central India"
    address_space = ["10.1.0.0/16"]

    subnet {
        name = "pub-sub"
        address_prefix = "10.1.0.0/24"
    }
}
resource "azurerm_network_interface" "app_interface" {
    name = "app-interface"
    location = "Central India"
    resource_group_name = "app_grp"

    ip_configuration {
        name = "internal"
        subnet_id = "pub-sub"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id = azurerm_public_ip.app_public_ip.id
    }
}
resource "azurerm_windows_virtual_machine" "myappvm" {
  name                = "app-machine"
  resource_group_name = "app_grp"
  location            = "Central India"
  size                = "Standard_B2ms"
  admin_username      = "stestuser"
  admin_password      = "siri@1234567"
  network_interface_ids = [
    azurerm_network_interface.app_interface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}
resource "azurerm_public_ip" "app_public_ip" {
  name                = "app-public-ip"
  resource_group_name = "app_grp"
  location            = "Central India"
  allocation_method   = "Static"
}
resource "azurerm_virtual_machine_extension" "vm_extension_install_iis" {
  name                       = "vm_extension_install_iis"
  virtual_machine_id         = azurerm_windows_virtual_machine.myappvm.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools"
    }
SETTINGS
}