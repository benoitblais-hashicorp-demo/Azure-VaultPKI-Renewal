import {
  to = azurerm_application_gateway.this
  id = format(
    "/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/applicationGateways/%s",
    var.subscription_id,
    "rg-${var.resource_suffix}",
    "${lower(replace(var.name_prefix, "_", "-"))}-appgw"
  )
}
