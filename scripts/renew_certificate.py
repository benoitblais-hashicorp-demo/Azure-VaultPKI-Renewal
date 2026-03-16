import json
import os
import subprocess
import tempfile
import urllib.error
import urllib.request
from pathlib import Path


def _require_env(name: str) -> str:
  value = os.getenv(name, "").strip()
  if not value:
    raise RuntimeError(f"Missing required environment variable: {name}")
  return value


def _request_vault_certificate() -> tuple[str, str, str]:
  vault_addr = _require_env("VAULT_ADDR").rstrip("/")
  vault_token = _require_env("VAULT_TOKEN")
  vault_pki_path = _require_env("VAULT_PKI_PATH").strip("/")
  vault_pki_role = _require_env("VAULT_PKI_ROLE")
  cert_common_name = _require_env("CERT_COMMON_NAME")
  cert_ttl = os.getenv("CERT_TTL", "24h")
  vault_namespace = os.getenv("VAULT_NAMESPACE", "").strip()

  issue_url = f"{vault_addr}/v1/{vault_pki_path}/issue/{vault_pki_role}"
  payload = json.dumps({
    "common_name": cert_common_name,
    "ttl": cert_ttl,
  }).encode("utf-8")

  request = urllib.request.Request(
    issue_url,
    data=payload,
    method="POST",
    headers={
      "Content-Type": "application/json",
      "X-Vault-Token": vault_token,
    },
  )

  if vault_namespace:
    request.add_header("X-Vault-Namespace", vault_namespace)

  try:
    with urllib.request.urlopen(request, timeout=30) as response:
      response_data = json.loads(response.read().decode("utf-8"))
  except urllib.error.HTTPError as error:
    body = error.read().decode("utf-8", errors="ignore")
    raise RuntimeError(f"Vault request failed: {error.code} {body}") from error

  data = response_data.get("data", {})
  certificate_body = data.get("certificate", "")
  private_key = data.get("private_key", "")
  issuing_ca = data.get("issuing_ca", "")
  ca_chain_items = data.get("ca_chain", [])

  if not certificate_body or not private_key:
    raise RuntimeError("Vault response did not include both certificate and private_key")

  certificate_chain = issuing_ca
  if ca_chain_items:
    certificate_chain = "\n".join(ca_chain_items)

  return certificate_body, private_key, certificate_chain


def _run(command: list[str]) -> str:
  completed = subprocess.run(command, check=True, capture_output=True, text=True)
  return completed.stdout.strip()


def main() -> None:
  key_vault_name = _require_env("AZURE_KEYVAULT_NAME")
  key_vault_cert_name = _require_env("AZURE_KEYVAULT_CERT_NAME")
  pfx_password = _require_env("PFX_PASSWORD")

  certificate_body, private_key, certificate_chain = _request_vault_certificate()

  with tempfile.TemporaryDirectory() as temp_dir:
    temp_path = Path(temp_dir)
    cert_file = temp_path / "certificate.pem"
    key_file = temp_path / "private_key.pem"
    chain_file = temp_path / "chain.pem"
    pfx_file = temp_path / "certificate.pfx"

    cert_file.write_text(certificate_body, encoding="utf-8")
    key_file.write_text(private_key, encoding="utf-8")
    chain_file.write_text(certificate_chain, encoding="utf-8")

    _run([
      "openssl",
      "pkcs12",
      "-export",
      "-out",
      str(pfx_file),
      "-inkey",
      str(key_file),
      "-in",
      str(cert_file),
      "-certfile",
      str(chain_file),
      "-passout",
      f"pass:{pfx_password}",
    ])

    _run([
      "az",
      "keyvault",
      "certificate",
      "import",
      "--vault-name",
      key_vault_name,
      "--name",
      key_vault_cert_name,
      "--file",
      str(pfx_file),
      "--password",
      pfx_password,
    ])

    certificate_json = _run([
      "az",
      "keyvault",
      "certificate",
      "show",
      "--vault-name",
      key_vault_name,
      "--name",
      key_vault_cert_name,
      "-o",
      "json",
    ])

  certificate_data = json.loads(certificate_json)
  print(json.dumps({
    "status": "success",
    "vault_common_name": _require_env("CERT_COMMON_NAME"),
    "key_vault_certificate_id": certificate_data.get("id", ""),
    "message": "Certificate renewed from Vault PKI and imported to Azure Key Vault",
  }))


if __name__ == "__main__":
  main()
