provider "cloudflare" {
  api_key = var.terraform.cloudflare.api_key
  email   = var.terraform.cloudflare.email
}

provider "github" {
  token = var.terraform.github.token
}

provider "oci" {
  fingerprint      = var.terraform.oci.fingerprint
  private_key_path = var.terraform.oci.private_key_path
  region           = var.terraform.oci.region
  tenancy_ocid     = var.terraform.oci.tenancy_ocid
  user_ocid        = var.terraform.oci.user_ocid
}

provider "onepassword" {
  account = var.terraform.onepassword.account
}

provider "openwrt" {
  alias    = "au"
  hostname = local.merged_servers["au.excloo.net"].tailscale_name
  password = local.merged_servers["au.excloo.net"].provider.password
  port     = local.merged_servers["au.excloo.net"].provider.port
}

provider "openwrt" {
  alias    = "kr"
  hostname = local.merged_servers["kr.excloo.net"].tailscale_name
  password = local.merged_servers["kr.excloo.net"].provider.password
  port     = local.merged_servers["kr.excloo.net"].provider.port
}

provider "proxmox" {
  alias     = "gen8"
  api_token = local.merged_servers["gen8.au.excloo.net"].provider.api_token
  endpoint  = "https://${local.merged_servers["gen8.au.excloo.net"].tailscale_name}:${local.merged_servers["gen8.au.excloo.net"].provider.port}/"
  insecure  = local.merged_servers["gen8.au.excloo.net"].provider.insecure

  ssh {
    agent    = true
    username = local.merged_servers["gen8.au.excloo.net"].user.username

    node {
      name    = local.merged_servers["gen8.au.excloo.net"].name
      address = local.merged_servers["gen8.au.excloo.net"].tailscale_name
    }
  }
}

provider "proxmox" {
  alias     = "kimbap"
  api_token = local.merged_servers["kimbap.kr.excloo.net"].provider.api_token
  endpoint  = "https://${local.merged_servers["kimbap.kr.excloo.net"].tailscale_name}:${local.merged_servers["kimbap.kr.excloo.net"].provider.port}/"
  insecure  = local.merged_servers["kimbap.kr.excloo.net"].provider.insecure

  ssh {
    agent    = true
    username = local.merged_servers["kimbap.kr.excloo.net"].user.username

    node {
      name    = local.merged_servers["kimbap.kr.excloo.net"].name
      address = local.merged_servers["kimbap.kr.excloo.net"].tailscale_name
    }
  }
}

provider "tailscale" {
  api_key = var.terraform.tailscale.api_key
  tailnet = var.terraform.tailscale.tailnet
}

terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    github = {
      source = "integrations/github"
    }
    htpasswd = {
      source = "loafoe/htpasswd"
    }
    oci = {
      source = "oracle/oci"
    }
    onepassword = {
      source = "1password/onepassword"
    }
    openwrt = {
      source = "joneshf/openwrt"
    }
    proxmox = {
      source = "bpg/proxmox"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
  }
}
