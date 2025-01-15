terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Excloo"

    workspaces {
      name = "Infrastructure"
    }
  }

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
    oci = {
      source = "oracle/oci"
    }
    onepassword = {
      source = "1password/onepassword"
    }
    proxmox = {
      source = "bpg/proxmox"
    }
    restapi = {
      source = "mastercard/restapi"
    }
    ssh = {
      source = "loafoe/ssh"
    }
    tailscale = {
      source = "tailscale/tailscale"
    }
  }
}
