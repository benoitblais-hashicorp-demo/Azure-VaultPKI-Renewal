import base64
import json
import os
import urllib.error
import urllib.parse
import urllib.request

try:
  import automationassets
except ImportError:  # local testing fallback
  automationassets = None


def _get_setting(name: str, required: bool = True, default: str = "") -> str:
  if automationassets is not None:
    value = automationassets.get_automation_variable(name)
    if value is None:
      value = ""
    value = str(value).strip()
  else:
    value = os.getenv(name, "").strip()

  if value:
    return value

  if required:
    raise RuntimeError(f"Missing required automation variable or environment variable: {name}")

  return default


def _http_json_request(
  url: str,
  method: str,
  payload: dict | None = None,
  headers: dict[str, str] | None = None,
  timeout_seconds: int = 30,
) -> dict:
  data = json.dumps(payload).encode("utf-8") if payload is not None else None
  request = urllib.request.Request(url, data=data, method=method)

  request.add_header("Content-Type", "application/json")
  if headers:
    for key, value in headers.items():
      request.add_header(key, value)

  try:
    with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
      response_body = response.read().decode("utf-8")
      return json.loads(response_body) if response_body else {}
  except urllib.error.HTTPError as error:
    body = error.read().decode("utf-8", errors="ignore")
    raise RuntimeError(f"HTTP request failed: {method} {url} -> {error.code} {body}") from error


def _get_managed_identity_token(resource: str) -> str:
  managed_identity_endpoint = "http://169.254.169.254/metadata/identity/oauth2/token"
  query = {
    "api-version": "2018-02-01",
    "resource": resource,
  }

  managed_identity_client_id = _get_setting("AZURE_MANAGED_IDENTITY_CLIENT_ID", required=False)
  if managed_identity_client_id:
    query["client_id"] = managed_identity_client_id

  url = f"{managed_identity_endpoint}?{urllib.parse.urlencode(query)}"
  response = _http_json_request(
    url=url,
    method="GET",
    headers={"Metadata": "true"},
    timeout_seconds=20,
  )

  access_token = response.get("access_token", "")
  if not access_token:
    raise RuntimeError("Managed identity token request did not return an access token")

  return access_token


def _vault_login_with_jwt(vault_addr: str, vault_namespace: str) -> str:
  vault_auth_path = _get_setting("VAULT_AUTH_PATH")
  vault_auth_role = _get_setting("VAULT_AUTH_ROLE")
  vault_jwt = _get_setting("VAULT_JWT", required=False)
  vault_jwt_audience = _get_setting("VAULT_JWT_AUDIENCE", required=False)

  if not vault_jwt:
    if not vault_jwt_audience:
      raise RuntimeError("`VAULT_JWT_AUDIENCE` is required when `VAULT_JWT` is not supplied.")

    vault_jwt = _get_managed_identity_token(vault_jwt_audience)

  login_url = f"{vault_addr}/v1/auth/{vault_auth_path.strip('/')}/login"
  headers = {}
  if vault_namespace:
    headers["X-Vault-Namespace"] = vault_namespace

  response_data = _http_json_request(
    url=login_url,
    method="POST",
    payload={"role": vault_auth_role, "jwt": vault_jwt},
    headers=headers,
  )

  client_token = (response_data.get("auth") or {}).get("client_token", "")
  if not client_token:
    raise RuntimeError("Vault JWT login did not return a client token")

  return client_token


def _get_vault_token(vault_addr: str, vault_namespace: str) -> str:
  vault_token = _get_setting("VAULT_TOKEN", required=False)
  if vault_token:
    return vault_token

  return _vault_login_with_jwt(vault_addr, vault_namespace)


def _request_vault_certificate() -> tuple[str, str, str]:
  vault_addr = _get_setting("VAULT_ADDR").rstrip("/")
  vault_namespace = _get_setting("VAULT_NAMESPACE", required=False)
  vault_pki_path = _get_setting("VAULT_PKI_PATH").strip("/")
  vault_pki_role = _get_setting("VAULT_PKI_ROLE")
  cert_common_name = _get_setting("CERT_COMMON_NAME")
  cert_ttl = _get_setting("CERT_TTL", required=False, default="24h")

  vault_token = _get_vault_token(vault_addr, vault_namespace)
  issue_url = f"{vault_addr}/v1/{vault_pki_path}/issue/{vault_pki_role}"
  headers = {"X-Vault-Token": vault_token}
  if vault_namespace:
    headers["X-Vault-Namespace"] = vault_namespace

  response_data = _http_json_request(
    url=issue_url,
    method="POST",
    payload={"common_name": cert_common_name, "ttl": cert_ttl},
    headers=headers,
  )

  data = response_data.get("data", {})
  certificate_body = data.get("certificate", "")
  private_key = data.get("private_key", "")
  issuing_ca = data.get("issuing_ca", "")
  ca_chain_items = data.get("ca_chain", [])

  if not certificate_body or not private_key:
    raise RuntimeError("Vault response did not include both `certificate` and `private_key`")

  certificate_chain = issuing_ca
  if ca_chain_items:
    certificate_chain = "\n".join(ca_chain_items)

  return certificate_body, private_key, certificate_chain


def _import_certificate_to_key_vault(certificate_pem_bundle: str) -> str:
  key_vault_name = _get_setting("AZURE_KEYVAULT_NAME")
  key_vault_cert_name = _get_setting("AZURE_KEYVAULT_CERT_NAME")
  key_vault_access_token = _get_managed_identity_token("https://vault.azure.net")
  import_url = f"https://{key_vault_name}.vault.azure.net/certificates/{key_vault_cert_name}/import?api-version=7.4"

  certificate_value = base64.b64encode(certificate_pem_bundle.encode("utf-8")).decode("utf-8")
  response = _http_json_request(
    url=import_url,
    method="POST",
    payload={
      "value": certificate_value,
      "policy": {
        "secret_props": {
          "contentType": "application/x-pem-file"
        }
      }
    },
    headers={"Authorization": f"Bearer {key_vault_access_token}"},
  )

  certificate_id = response.get("id", "")
  if not certificate_id:
    raise RuntimeError("Key Vault certificate import did not return a certificate id")

  return certificate_id


def main() -> None:
  certificate_body, private_key, certificate_chain = _request_vault_certificate()

  pem_parts = [certificate_body, private_key]
  if certificate_chain:
    pem_parts.append(certificate_chain)
  certificate_pem_bundle = "\n".join([part.strip() for part in pem_parts if part and part.strip()])

  key_vault_certificate_id = _import_certificate_to_key_vault(certificate_pem_bundle)

  print(json.dumps({
    "status": "success",
    "key_vault_certificate_id": key_vault_certificate_id,
    "message": "Certificate renewed from Vault PKI and imported to Azure Key Vault.",
  }))


if __name__ == "__main__":
  main()
