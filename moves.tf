moved {
  from = azurerm_key_vault.this
  to   = module.keyvault.azurerm_key_vault.this
}

moved {
  from = azurerm_storage_account.automation_packages
  to   = module.storage_account.azurerm_storage_account.this
}

moved {
  from = azurerm_storage_container.automation_packages
  to   = module.storage_account.azurerm_storage_container.this["python-packages"]
}

moved {
  from = azurerm_storage_blob.cryptography_wheel
  to   = module.storage_account.azurerm_storage_blob.this["python-packages/cryptography-3.2.1-cp38-cp38-win_amd64.whl"]
}
