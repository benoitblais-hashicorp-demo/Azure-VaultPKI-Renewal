import base64
import json
import os
import ssl
import subprocess
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import shutil
from typing import Dict, Optional, Tuple

try:
  import automationassets
except ImportError:  # local testing fallback
  automationassets = None


def _get_setting(name: str, required: bool = True, default: str = "") -> str:
  if automationassets is not None:
    try:
      value = automationassets.get_automation_variable(name)
    except Exception:
      value = ""
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


def _get_bool_setting(name: str, default: bool = False) -> bool:
  raw_value = _get_setting(name, required=False, default=str(default))
  return raw_value.strip().lower() in {"1", "true", "yes", "on"}


def _build_ssl_context() -> Optional[ssl.SSLContext]:
  if _get_bool_setting("VAULT_TLS_SKIP_VERIFY", default=False):
    context = ssl.create_default_context()
    context.check_hostname = False
    context.verify_mode = ssl.CERT_NONE
    return context

  return None


def _http_json_request(
  url: str,
  method: str,
  payload: Optional[Dict] = None,
  headers: Optional[Dict[str, str]] = None,
  timeout_seconds: int = 30,
) -> Dict:
  data = json.dumps(payload).encode("utf-8") if payload is not None else None
  request = urllib.request.Request(url, data=data, method=method)

  request.add_header("Content-Type", "application/json")
  if headers:
    for key, value in headers.items():
      request.add_header(key, value)

  try:
    ssl_context = _build_ssl_context()
    with urllib.request.urlopen(request, timeout=timeout_seconds, context=ssl_context) as response:
      response_body = response.read().decode("utf-8")
      return json.loads(response_body) if response_body else {}
  except urllib.error.HTTPError as error:
    body = error.read().decode("utf-8", errors="ignore")
    raise RuntimeError(f"HTTP request failed: {method} {url} -> {error.code} {body}") from error


def _get_managed_identity_token(resource: str) -> str:
  managed_identity_client_id = _get_setting("AZURE_MANAGED_IDENTITY_CLIENT_ID", required=False)

  identity_endpoint = os.getenv("IDENTITY_ENDPOINT", "").strip()
  identity_header = os.getenv("IDENTITY_HEADER", "").strip()
  if identity_endpoint and identity_header:
    query = {
      "api-version": "2019-08-01",
      "resource": resource,
    }
    if managed_identity_client_id:
      query["client_id"] = managed_identity_client_id

    url = f"{identity_endpoint}?{urllib.parse.urlencode(query)}"
    response = _http_json_request(
      url=url,
      method="GET",
      headers={"X-IDENTITY-HEADER": identity_header},
      timeout_seconds=20,
    )
  else:
    managed_identity_endpoint = "http://169.254.169.254/metadata/identity/oauth2/token"
    query = {
      "api-version": "2018-02-01",
      "resource": resource,
    }
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


def _vault_login_with_approle(vault_addr: str, vault_namespace: str) -> str:
  vault_auth_path = _get_setting("VAULT_AUTH_PATH")
  role_id = _get_setting("VAULT_APPROLE_ROLE_ID")
  secret_id = _get_setting("VAULT_APPROLE_SECRET_ID")

  login_url = f"{vault_addr}/v1/auth/{vault_auth_path.strip('/')}/login"
  headers = {}
  if vault_namespace:
    headers["X-Vault-Namespace"] = vault_namespace

  response_data = _http_json_request(
    url=login_url,
    method="POST",
    payload={"role_id": role_id, "secret_id": secret_id},
    headers=headers,
  )

  client_token = (response_data.get("auth") or {}).get("client_token", "")
  if not client_token:
    raise RuntimeError("Vault AppRole login did not return a client token")

  return client_token


def _request_vault_certificate() -> Tuple[str, str, str]:
  vault_addr = _get_setting("VAULT_ADDR").rstrip("/")
  vault_namespace = _get_setting("VAULT_NAMESPACE", required=False)
  vault_pki_path = _get_setting("VAULT_PKI_PATH").strip("/")
  vault_pki_role = _get_setting("VAULT_PKI_ROLE")
  cert_common_name = _get_setting("CERT_COMMON_NAME")
  cert_ttl = _get_setting("CERT_TTL", required=False, default="24h")

  vault_token = _vault_login_with_approle(vault_addr, vault_namespace)
  issue_url = f"{vault_addr}/v1/{vault_pki_path}/issue/{vault_pki_role}"
  headers = {"X-Vault-Token": vault_token}
  if vault_namespace:
    headers["X-Vault-Namespace"] = vault_namespace

  response_data = _http_json_request(
    url=issue_url,
    method="POST",
    payload={
      "common_name": cert_common_name,
      "ttl": cert_ttl,
      "format": "pem",
      "private_key_format": "pkcs8",
    },
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


def _build_pfx_bundle(
  private_key_pem: str,
  certificate_pem: str,
  certificate_chain_pem: str,
  pfx_password: str,
) -> bytes:
  if not pfx_password:
    raise RuntimeError("PFX password is required to build PKCS12 bundle")

  openssl_path = shutil.which("openssl")
  if not openssl_path:
    try:
      return _build_pfx_bundle_with_cryptography(
        private_key_pem=private_key_pem,
        certificate_pem=certificate_pem,
        certificate_chain_pem=certificate_chain_pem,
        pfx_password=pfx_password,
      )
    except Exception as error:
      raise RuntimeError(
        "OpenSSL was not found and cryptography could not build the PFX bundle. "
        "Install OpenSSL in the automation environment or add the cryptography package."
      ) from error

  with tempfile.TemporaryDirectory() as temp_dir:
    key_path = os.path.join(temp_dir, "key.pem")
    cert_path = os.path.join(temp_dir, "cert.pem")
    chain_path = os.path.join(temp_dir, "chain.pem")
    pfx_path = os.path.join(temp_dir, "bundle.pfx")

    with open(key_path, "w", encoding="utf-8") as handle:
      handle.write(private_key_pem.strip() + "\n")

    with open(cert_path, "w", encoding="utf-8") as handle:
      handle.write(certificate_pem.strip() + "\n")

    chain_arg = []
    if certificate_chain_pem.strip():
      with open(chain_path, "w", encoding="utf-8") as handle:
        handle.write(certificate_chain_pem.strip() + "\n")
      chain_arg = ["-certfile", chain_path]

    command = [
      "openssl",
      "pkcs12",
      "-export",
      "-out",
      pfx_path,
      "-inkey",
      key_path,
      "-in",
      cert_path,
    ] + chain_arg + [
      "-passout",
      f"pass:{pfx_password}",
    ]

    try:
      subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except FileNotFoundError as error:
      raise RuntimeError("OpenSSL is required to build PFX bundle but was not found") from error
    except subprocess.CalledProcessError as error:
      stderr = error.stderr.decode("utf-8", errors="ignore")
      raise RuntimeError(f"Failed to build PFX bundle: {stderr}") from error

    with open(pfx_path, "rb") as handle:
      return handle.read()


def _split_pem_certificates(pem_bundle: str) -> Tuple[str, ...]:
  marker = "-----END CERTIFICATE-----"
  if not pem_bundle.strip():
    return ()

  certs = []
  remainder = pem_bundle.strip()
  while marker in remainder:
    before, _, after = remainder.partition(marker)
    cert = (before + marker).strip()
    if cert:
      certs.append(cert + "\n")
    remainder = after.strip()

  return tuple(certs)


def _build_pfx_bundle_with_cryptography(
  private_key_pem: str,
  certificate_pem: str,
  certificate_chain_pem: str,
  pfx_password: str,
) -> bytes:
  try:
    import cryptography
    from cryptography import x509
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.serialization import pkcs12
  except Exception as error:
    raise RuntimeError("cryptography is not available in the automation runtime") from error

  crypto_version = getattr(cryptography, "__version__", "unknown")
  crypto_path = getattr(cryptography, "__file__", "unknown")

  if not hasattr(pkcs12, "serialize_key_and_certificates"):
    raise RuntimeError(
      f"cryptography {crypto_version} at {crypto_path} is too old to build PKCS12 bundles. "
      "Install a newer cryptography package (v2.5+), or install OpenSSL."
    )

  key = serialization.load_pem_private_key(
    private_key_pem.encode("utf-8"),
    password=None,
    backend=default_backend(),
  )
  certificate = x509.load_pem_x509_certificate(
    certificate_pem.encode("utf-8"),
    default_backend(),
  )

  chain = []
  for cert_pem in _split_pem_certificates(certificate_chain_pem):
    chain.append(
      x509.load_pem_x509_certificate(
        cert_pem.encode("utf-8"),
        default_backend(),
      )
    )

  return pkcs12.serialize_key_and_certificates(
    name=b"vault-pki",
    key=key,
    cert=certificate,
    cas=chain or None,
    encryption_algorithm=serialization.BestAvailableEncryption(pfx_password.encode("utf-8")),
  )


def _import_certificate_to_key_vault(pfx_bytes: bytes, pfx_password: str) -> str:
  key_vault_name = _get_setting("AZURE_KEYVAULT_NAME")
  key_vault_cert_name = _get_setting("AZURE_KEYVAULT_CERT_NAME")
  key_vault_access_token = _get_managed_identity_token("https://vault.azure.net")
  import_url = f"https://{key_vault_name}.vault.azure.net/certificates/{key_vault_cert_name}/import?api-version=7.4"

  certificate_value = base64.b64encode(pfx_bytes).decode("utf-8")
  response = _http_json_request(
    url=import_url,
    method="POST",
    payload={
      "value": certificate_value,
      "pwd": pfx_password,
      "policy": {
        "secret_props": {
          "contentType": "application/x-pkcs12"
        }
      }
    },
    headers={"Authorization": f"Bearer {key_vault_access_token}"},
  )

  certificate_id = response.get("id", "")
  if not certificate_id:
    raise RuntimeError("Key Vault certificate import did not return a certificate id")

  return certificate_id


def _get_key_vault_secret_id() -> str:
  key_vault_name = _get_setting("AZURE_KEYVAULT_NAME")
  key_vault_cert_name = _get_setting("AZURE_KEYVAULT_CERT_NAME")
  key_vault_access_token = _get_managed_identity_token("https://vault.azure.net")

  secret_url = (
    f"https://{key_vault_name}.vault.azure.net/secrets/"
    f"{key_vault_cert_name}?api-version=7.4"
  )
  response = _http_json_request(
    url=secret_url,
    method="GET",
    headers={"Authorization": f"Bearer {key_vault_access_token}"},
  )

  secret_id = response.get("id", "")
  if not secret_id:
    raise RuntimeError("Key Vault secret lookup did not return a secret id")

  return secret_id


def _update_app_gateway_ssl_cert(secret_id: str) -> None:
  subscription_id = _get_setting("AZURE_SUBSCRIPTION_ID")
  app_gateway_resource_group = _get_setting("AZURE_APP_GATEWAY_RESOURCE_GROUP")
  app_gateway_name = _get_setting("AZURE_APP_GATEWAY_NAME")
  app_gateway_ssl_cert_name = _get_setting("AZURE_APP_GATEWAY_SSL_CERT_NAME")

  arm_token = _get_managed_identity_token("https://management.azure.com/")
  base_url = (
    "https://management.azure.com/subscriptions/"
    f"{subscription_id}/resourceGroups/{app_gateway_resource_group}"
    f"/providers/Microsoft.Network/applicationGateways/{app_gateway_name}"
  )

  # Some regions return 404 for the sslCertificates subresource. Update via the parent resource instead.
  api_versions = ["2023-11-01", "2022-09-01", "2021-08-01"]
  last_error: Optional[Exception] = None

  for api_version in api_versions:
    resource_url = f"{base_url}?api-version={api_version}"
    try:
      gateway = _http_json_request(
        url=resource_url,
        method="GET",
        headers={"Authorization": f"Bearer {arm_token}"},
      )

      properties = gateway.get("properties", {})
      ssl_certs = properties.get("sslCertificates", [])
      updated = False

      for cert in ssl_certs:
        if cert.get("name") == app_gateway_ssl_cert_name:
          cert.setdefault("properties", {})["keyVaultSecretId"] = secret_id
          updated = True
          break

      if not updated:
        ssl_certs.append({
          "name": app_gateway_ssl_cert_name,
          "properties": {"keyVaultSecretId": secret_id},
        })

      # PATCH only supports tags for Application Gateway; use PUT with full payload instead.
      payload = {key: value for key, value in gateway.items() if key not in {"id", "type", "etag"}}
      payload["properties"] = properties

      _http_json_request(
        url=resource_url,
        method="PUT",
        payload=payload,
        headers={"Authorization": f"Bearer {arm_token}"},
      )
      return
    except RuntimeError as error:
      last_error = error
      if " -> 404 " not in str(error):
        raise

  if last_error:
    raise last_error


def main() -> None:
  certificate_body, private_key, certificate_chain = _request_vault_certificate()

  pfx_password = _get_setting("PFX_PASSWORD")
  pfx_bytes = _build_pfx_bundle(
    private_key_pem=private_key,
    certificate_pem=certificate_body,
    certificate_chain_pem=certificate_chain,
    pfx_password=pfx_password,
  )

  key_vault_certificate_id = _import_certificate_to_key_vault(pfx_bytes, pfx_password)
  key_vault_secret_id = _get_key_vault_secret_id()

  _update_app_gateway_ssl_cert(key_vault_secret_id)

  print(json.dumps({
    "status": "success",
    "key_vault_certificate_id": key_vault_certificate_id,
    "key_vault_secret_id": key_vault_secret_id,
    "message": "Certificate renewed from Vault PKI and imported to Azure Key Vault.",
  }))


if __name__ == "__main__":
  main()
