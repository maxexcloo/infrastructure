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
    openwrt = {
      source = "joneshf/openwrt"
    }
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}
