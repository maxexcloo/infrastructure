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
  account = var.terraform.onepassword.account
}

provider "openwrt" {
  alias    = "au"
  hostname = local.routers["au"].host
  password = local.routers["au"].provider.password
  port     = local.routers["au"].provider.port
}

provider "openwrt" {
  alias    = "kr"
  hostname = local.routers["kr"].host
  password = local.routers["kr"].provider.password
  port     = local.routers["kr"].provider.port
}

provider "proxmox" {
  alias     = "gen8"
  api_token = local.servers_proxmox["au-gen8"].provider.api_token
  endpoint  = "https://${local.servers_proxmox["au-gen8"].host}:${local.servers_proxmox["au-gen8"].provider.port}"
  insecure  = local.servers_proxmox["au-gen8"].provider.insecure

  ssh {
    agent    = true
    username = local.servers_proxmox["au-gen8"].user.username

    node {
      name    = local.servers_proxmox["au-gen8"].name
      address = local.servers_proxmox["au-gen8"].host
    }
  }
}

provider "proxmox" {
  alias     = "kimbap"
  api_token = local.servers_proxmox["kr-kimbap"].provider.api_token
  endpoint  = "https://${local.servers_proxmox["kr-kimbap"].host}:${local.servers_proxmox["kr-kimbap"].provider.port}"
  insecure  = local.servers_proxmox["kr-kimbap"].provider.insecure

  ssh {
    agent    = true
    username = local.servers_proxmox["kr-kimbap"].user.username

    node {
      name    = local.servers_proxmox["kr-kimbap"].name
      address = local.servers_proxmox["kr-kimbap"].host
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
  api_key = var.terraform.tailscale.api_key
  tailnet = var.terraform.tailscale.tailnet
}
