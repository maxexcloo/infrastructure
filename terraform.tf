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
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}
