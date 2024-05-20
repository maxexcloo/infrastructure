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
  hostname = local.servers["au.excloo.net"].host
  password = local.servers["au.excloo.net"].provider.password
  port     = local.servers["au.excloo.net"].provider.port
}

provider "openwrt" {
  alias    = "kr"
  hostname = local.servers["kr.excloo.net"].host
  password = local.servers["kr.excloo.net"].provider.password
  port     = local.servers["kr.excloo.net"].provider.port
}

provider "proxmox" {
  alias     = "gen8"
  api_token = local.servers["gen8.au.excloo.net"].provider.api_token
  endpoint  = "https://${local.servers["gen8.au.excloo.net"].host}:${local.servers["gen8.au.excloo.net"].provider.port}/"
  insecure  = local.servers["gen8.au.excloo.net"].provider.insecure

  ssh {
    agent    = true
    username = local.servers["gen8.au.excloo.net"].user.username

    node {
      name    = local.servers["gen8.au.excloo.net"].name
      address = local.servers["gen8.au.excloo.net"].host
    }
  }
}

provider "proxmox" {
  alias     = "kimbap"
  api_token = local.servers["kimbap.kr.excloo.net"].provider.api_token
  endpoint  = "https://${local.servers["kimbap.kr.excloo.net"].host}:${local.servers["kimbap.kr.excloo.net"].provider.port}/"
  insecure  = local.servers["kimbap.kr.excloo.net"].provider.insecure

  ssh {
    agent    = true
    username = local.servers["kimbap.kr.excloo.net"].user.username

    node {
      name    = local.servers["kimbap.kr.excloo.net"].name
      address = local.servers["kimbap.kr.excloo.net"].host
    }
  }
}

provider "tailscale" {
  api_key = var.terraform.tailscale.api_key
  tailnet = var.terraform.tailscale.tailnet
}
