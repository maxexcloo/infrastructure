provider "cloudflare" {
  api_key = var.cloudflare.api_key
  email   = var.cloudflare.email
}

provider "github" {
  token = var.github.token
}

provider "oci" {
  fingerprint      = var.oci.fingerprint
  private_key_path = var.oci.private_key_path
  region           = var.oci.region
  tenancy_ocid     = var.oci.tenancy_ocid
  user_ocid        = var.oci.user_ocid
}

provider "openwrt" {
  alias    = "au"
  hostname = var.openwrt.au.hostname
  password = var.openwrt.au.password
  port     = var.openwrt.au.port
}

provider "openwrt" {
  alias    = "kr"
  hostname = var.openwrt.kr.hostname
  password = var.openwrt.kr.password
  port     = var.openwrt.kr.port
}

provider "proxmox" {
  alias     = "gen8"
  api_token = var.proxmox.gen8.api_token
  endpoint  = var.proxmox.gen8.endpoint
  insecure  = var.proxmox.insecure

  ssh {
    agent    = true
    username = var.proxmox.username

    node {
      name    = var.proxmox.gen8.name
      address = var.proxmox.gen8.ssh_address
    }
  }
}

provider "proxmox" {
  alias     = "kimbap"
  api_token = var.proxmox.kimbap.api_token
  endpoint  = var.proxmox.kimbap.endpoint
  insecure  = var.proxmox.insecure

  ssh {
    agent    = true
    username = var.proxmox.username

    node {
      name    = var.proxmox.kimbap.name
      address = var.proxmox.kimbap.ssh_address
    }
  }
}
