provider "b2" {
  application_key    = var.terraform.b2.application_key
  application_key_id = var.terraform.b2.application_key_id
}

provider "cloudflare" {
  api_key = var.terraform.cloudflare.api_key
  email   = var.terraform.cloudflare.email
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
  password = local.routers["au"].provider.password
  port     = local.routers["au"].provider.port
}

provider "openwrt" {
  alias    = "kr"
  hostname = "kr"
  password = local.routers["kr"].provider.password
  port     = local.routers["kr"].provider.port
}

provider "proxmox" {
  alias     = "gen8"
  api_token = local.servers_proxmox["au-gen8"].provider.api_token
  endpoint  = "https://au-gen8:${local.servers_proxmox["au-gen8"].provider.port}"
  insecure  = local.servers_proxmox["au-gen8"].provider.insecure

  ssh {
    agent    = true
    username = local.servers_proxmox["au-gen8"].user.username

    node {
      address = "au-gen8"
      name    = local.servers_proxmox["au-gen8"].name
    }
  }
}

provider "proxmox" {
  alias     = "kimbap"
  api_token = local.servers_proxmox["kr-kimbap"].provider.api_token
  endpoint  = "https://kr-kimbap:${local.servers_proxmox["kr-kimbap"].provider.port}"
  insecure  = local.servers_proxmox["kr-kimbap"].provider.insecure

  ssh {
    agent    = true
    username = local.servers_proxmox["kr-kimbap"].user.username

    node {
      address = "kr-kimbap"
      name    = local.servers_proxmox["kr-kimbap"].name
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
  tailnet             = var.terraform.tailscale.tailnet
}
