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
  hostname = var.terraform.openwrt.au.hostname
  password = var.terraform.openwrt.au.password
  port     = var.terraform.openwrt.au.port
}

provider "openwrt" {
  alias    = "kr"
  hostname = var.terraform.openwrt.kr.hostname
  password = var.terraform.openwrt.kr.password
  port     = var.terraform.openwrt.kr.port
}

provider "proxmox" {
  alias     = "gen8"
  api_token = var.terraform.proxmox.gen8.api_token
  endpoint  = var.terraform.proxmox.gen8.endpoint
  insecure  = var.terraform.proxmox.insecure

  ssh {
    agent    = true
    username = var.terraform.proxmox.username

    node {
      name    = var.terraform.proxmox.gen8.name
      address = var.terraform.proxmox.gen8.ssh_address
    }
  }
}

provider "proxmox" {
  alias     = "kimbap"
  api_token = var.terraform.proxmox.kimbap.api_token
  endpoint  = var.terraform.proxmox.kimbap.endpoint
  insecure  = var.terraform.proxmox.insecure

  ssh {
    agent    = true
    username = var.terraform.proxmox.username

    node {
      name    = var.terraform.proxmox.kimbap.name
      address = var.terraform.proxmox.kimbap.ssh_address
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
    oci = {
      source = "oracle/oci"
    }
    onepassword = {
      source = "1Password/onepassword"
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
