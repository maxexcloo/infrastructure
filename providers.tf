provider "b2" {
  application_key    = var.terraform.b2.application_key
  application_key_id = var.terraform.b2.application_key_id
}

provider "cloudflare" {
  api_key = var.terraform.cloudflare.api_key
  email   = var.default.email
}

provider "github" {
  token = var.terraform.github.token
}

provider "oci" {
  fingerprint  = var.terraform.oci.fingerprint
  private_key  = base64decode(var.terraform.oci.private_key)
  region       = var.terraform.oci.region
  tenancy_ocid = var.terraform.oci.tenancy_ocid
  user_ocid    = var.terraform.oci.user_ocid
}

provider "onepassword" {
  service_account_token = var.terraform.onepassword.service_account_token
}

provider "openwrt" {
  alias    = "au"
  hostname = "au"
  password = local.merged_routers["au"].provider.password
  port     = local.merged_routers["au"].provider.port
}

provider "openwrt" {
  alias    = "kr"
  hostname = "kr"
  password = local.merged_routers["kr"].provider.password
  port     = local.merged_routers["kr"].provider.port
}

provider "proxmox" {
  endpoint = "https://au-pie:${local.merged_servers_proxmox["au-pie"].provider.port}"
  insecure = local.merged_servers_proxmox["au-pie"].provider.insecure
  password = local.merged_servers_proxmox["au-pie"].provider.password
  username = "${local.merged_servers_proxmox["au-pie"].provider.username}@pam"

  ssh {
    agent    = true
    username = local.merged_servers_proxmox["au-pie"].provider.username

    node {
      address = "au-pie"
      name    = local.merged_servers_proxmox["au-pie"].name
    }
  }
}

provider "restapi" {
  alias                 = "resend"
  create_returns_object = true
  rate_limit            = 1
  uri                   = "https://api.resend.com"

  headers = {
    "Authorization" = "Bearer ${var.terraform.resend.api_key}",
    "Content-Type"  = "application/json"
  }
}

provider "tailscale" {
  oauth_client_id     = var.terraform.tailscale.oauth_client_id
  oauth_client_secret = var.terraform.tailscale.oauth_client_secret
  tailnet             = var.default.domain_root
}
