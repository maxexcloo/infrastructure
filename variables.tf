variable "default" {
  description = "Default configuration values including domains, email, and infrastructure defaults"
  type = object({
    domain_external = string
    domain_internal = string
    domain_root     = string
    email           = string
    name            = string
    organisation    = string
  })
  default = {
    domain_external = "excloo.net"
    domain_internal = "excloo.org"
    domain_root     = "excloo.com"
    email           = "max@excloo.com"
    name            = "Max Schaefer"
    organisation    = "excloo"
  }
}

variable "devices" {
  description = "Device configurations for network infrastructure"
  type        = any

  validation {
    condition = alltrue([
      for k, v in var.devices : v != null && v != {}
    ])
    error_message = "Device configurations cannot be null or empty."
  }
}

variable "dns" {
  description = "DNS record configurations for all domains and zones"
  type        = any

  validation {
    condition = alltrue([
      for k, v in var.dns : v != null && v != {}
    ])
    error_message = "DNS configurations cannot be null or empty."
  }
}

variable "routers" {
  description = "Router configurations for network infrastructure"
  type        = any

  validation {
    condition = alltrue([
      for k, v in var.routers : v != null && v != {}
    ])
    error_message = "Router configurations cannot be null or empty."
  }
}

variable "servers" {
  description = "Server configurations for infrastructure deployment"
  type        = any

  validation {
    condition = alltrue([
      for k, v in var.servers : v != null && v != {}
    ])
    error_message = "Server configurations cannot be null or empty."
  }
}

variable "tags" {
  default     = {}
  description = "Common tags to apply to all infrastructure resources"
  type        = map(string)

  validation {
    condition = alltrue([
      for k, v in var.tags : can(regex("^[a-zA-Z][a-zA-Z0-9_-]*$", k))
    ])
    error_message = "Tag keys must start with a letter and contain only alphanumeric characters, underscores, and hyphens."
  }
}

variable "terraform" {
  description = "Terraform provider configurations and API credentials"
  sensitive   = true
  type = object({
    b2 = object({
      application_key    = string
      application_key_id = string
    })
    cloudflare = object({
      account_id = string
      api_key    = string
    })
    github = object({
      repository = string
      token      = string
      username   = string
    })
    oci = object({
      fingerprint  = string
      location     = string
      private_key  = string
      region       = string
      tenancy_ocid = string
      user_ocid    = string
    })
    onepassword = object({
      service_account_token = string
      vault                 = string
    })
    proxmox = object({
      pie = object({
        host     = string
        password = string
        port     = number
        username = string
      })
    })
    resend = object({
      api_key = string
      url     = string
    })
    sftpgo = object({
      home_directory_base = string
      host                = string
      password            = string
      username            = string
      webdav_url          = string
    })
    tailscale = object({
      oauth_client_id     = string
      oauth_client_secret = string
      organization        = string
    })
  })
}

variable "vms" {
  description = "Virtual machine configurations for all platforms"
  type        = any

  validation {
    condition = alltrue([
      for k, v in var.vms : v != null && v != {}
    ])
    error_message = "VM configurations cannot be null or empty."
  }
}

variable "vms_oci" {
  description = "Oracle Cloud Infrastructure virtual machine configurations"
  type        = any

  validation {
    condition = alltrue([
      for k, v in var.vms_oci : v != null && v != {}
    ])
    error_message = "OCI VM configurations cannot be null or empty."
  }
}

variable "vms_proxmox" {
  description = "Proxmox virtual machine configurations"
  type        = any

  validation {
    condition = alltrue([
      for k, v in var.vms_proxmox : v != null && v != {}
    ])
    error_message = "Proxmox VM configurations cannot be null or empty."
  }
}
