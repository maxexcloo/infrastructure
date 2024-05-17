terraform {
  required_providers {
    b2 = {
      source = "backblaze/b2"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    github = {
      source = "integrations/github"
    }
    htpasswd = {
      source = "loafoe/htpasswd"
    }
    macaddress = {
      source = "ivoronin/macaddress"
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
    random = {
      source = "hashicorp/random"
    }
    ssh = {
      source = "loafoe/ssh"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
  }
}
